// lavalamp_se_signer.swift — Apple Secure Enclave signing helper
// for the LavaLamp daemon (LL-043).
//
// The Secure Enclave generates a P-256 ECDSA keypair whose
// **private key never leaves the SE** — it can only be referenced
// by SecKeyRef + used for SE-mediated signing operations. Public
// key is exportable.
//
// Subcommands:
//
//   init  --pubkey-out PATH
//     Generate a fresh SE-bound P-256 keypair, store with label
//     "lavalamp.signer". Export the 33-byte compressed public
//     key to PATH (mode 0644). Replaces any previously-existing
//     "lavalamp.signer" key.
//
//   sign  --hex MESSAGE_HEX
//     Read the SE-bound key by label, sign SHA-256(message) via
//     ECDSA, output the signature as raw 64-byte r||s in hex
//     to stdout.
//
//   purge
//     Delete the "lavalamp.signer" SE key from the keychain.
//     Called by daemon atexit hook to ensure per-startup key
//     freshness.
//
// Build:
//
//   swiftc -framework Security -framework CoreFoundation \
//          lavalamp_se_signer.swift -o lavalamp_se_signer
//
// Author: Aaron Green, 2026.
// License: Triadic Closure License (TCL v1.3).

import Foundation
import Security

let KEY_LABEL = "lavalamp.signer"

// MARK: - Helpers

func die(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

func hexToData(_ hex: String) -> Data? {
    let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count % 2 == 0 else { return nil }
    var data = Data(capacity: trimmed.count / 2)
    var index = trimmed.startIndex
    while index < trimmed.endIndex {
        let next = trimmed.index(index, offsetBy: 2)
        guard let byte = UInt8(trimmed[index..<next], radix: 16) else {
            return nil
        }
        data.append(byte)
        index = next
    }
    return data
}

func dataToHex(_ data: Data) -> String {
    return data.map { String(format: "%02x", $0) }.joined()
}

// MARK: - Keychain query helpers

func deleteKey(label: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrLabel as String: label,
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    ]
    SecItemDelete(query as CFDictionary)  // ignore errSecItemNotFound
}

func loadKey(label: String) -> SecKey? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrLabel as String: label,
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let key = item else { return nil }
    return (key as! SecKey)
}

// MARK: - Public-key export (uncompressed → compressed)

/// Returns the 33-byte compressed SEC1 encoding of an ECDSA P-256
/// public key: 0x02 or 0x03 prefix (depending on Y parity) + 32-byte X.
/// Apple's `SecKeyCopyExternalRepresentation` gives uncompressed form
/// (0x04 + 32 X + 32 Y); we compress it ourselves.
func compressPublicKey(_ uncompressed: Data) -> Data? {
    guard uncompressed.count == 65, uncompressed[0] == 0x04 else { return nil }
    let xBytes = uncompressed.subdata(in: 1..<33)
    let yLastByte = uncompressed[64]
    let prefix: UInt8 = (yLastByte & 0x01) == 0 ? 0x02 : 0x03
    var out = Data([prefix])
    out.append(xBytes)
    return out
}

// MARK: - DER signature → raw r||s

/// Converts an ASN.1 DER-encoded ECDSA signature (as Apple's
/// SecKeyCreateSignature returns) to fixed 64-byte raw r||s
/// (32-byte r, 32-byte s, big-endian, zero-padded if shorter).
///
/// Minimal DER parser — handles the standard SEQUENCE { INTEGER r,
/// INTEGER s } shape that ECDSA emits. Robust against the leading-
/// zero padding ECDSA inserts when r or s have the high bit set.
func derToRaw64(_ der: Data) -> Data? {
    var idx = 0
    func readByte() -> UInt8? {
        guard idx < der.count else { return nil }
        let b = der[idx]; idx += 1; return b
    }
    func readLength() -> Int? {
        guard let first = readByte() else { return nil }
        if first & 0x80 == 0 { return Int(first) }
        let nBytes = Int(first & 0x7f)
        guard nBytes > 0, nBytes <= 4 else { return nil }
        var len = 0
        for _ in 0..<nBytes {
            guard let b = readByte() else { return nil }
            len = (len << 8) | Int(b)
        }
        return len
    }
    func readInteger() -> Data? {
        guard readByte() == 0x02 else { return nil }
        guard let len = readLength() else { return nil }
        guard idx + len <= der.count else { return nil }
        var int = der.subdata(in: idx..<(idx + len))
        idx += len
        // Strip leading zero (DER negative-prevention padding).
        while int.count > 32 && int.first == 0x00 {
            int = int.subdata(in: 1..<int.count)
        }
        // Left-pad to 32 bytes.
        if int.count < 32 {
            int = Data(repeating: 0x00, count: 32 - int.count) + int
        }
        guard int.count == 32 else { return nil }
        return int
    }
    guard readByte() == 0x30 else { return nil }
    guard let _ = readLength() else { return nil }
    guard let r = readInteger() else { return nil }
    guard let s = readInteger() else { return nil }
    return r + s
}

// MARK: - Subcommands

func cmdInit(pubkeyPath: String) {
    // Replace any pre-existing key with the same label (per-startup
    // freshness; matches LavaLamp daemon's per-startup key model).
    deleteKey(label: KEY_LABEL)

    // Configure SE-bound key access.
    var error: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
        kCFAllocatorDefault,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        .privateKeyUsage,
        &error
    ) else {
        if let err = error?.takeRetainedValue() {
            die("SecAccessControlCreateWithFlags failed: \(err)")
        }
        die("SecAccessControlCreateWithFlags failed (unknown error)")
    }

    let attrs: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: 256,
        kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
        kSecPrivateKeyAttrs as String: [
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: KEY_LABEL,
            kSecAttrAccessControl as String: access,
        ],
    ]

    var keygenError: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(
        attrs as CFDictionary,
        &keygenError
    ) else {
        if let err = keygenError?.takeRetainedValue() {
            die("SecKeyCreateRandomKey failed: \(err)")
        }
        die("SecKeyCreateRandomKey failed (unknown error)")
    }

    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        die("SecKeyCopyPublicKey returned nil")
    }

    var pubExportError: Unmanaged<CFError>?
    guard let pubData = SecKeyCopyExternalRepresentation(
        publicKey, &pubExportError
    ) as Data? else {
        if let err = pubExportError?.takeRetainedValue() {
            die("SecKeyCopyExternalRepresentation failed: \(err)")
        }
        die("SecKeyCopyExternalRepresentation failed (unknown error)")
    }

    guard let compressed = compressPublicKey(pubData) else {
        die("compressPublicKey failed (uncompressed len was \(pubData.count))")
    }

    // Write compressed pubkey to the path with mode 0644.
    let url = URL(fileURLWithPath: pubkeyPath)
    do {
        try compressed.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o644],
            ofItemAtPath: pubkeyPath
        )
    } catch {
        die("failed to write pubkey to \(pubkeyPath): \(error)")
    }

    print("init: SE-bound P-256 key created, compressed pub written to \(pubkeyPath) (\(compressed.count) bytes)")
}

func cmdSign(messageHex: String) {
    guard let message = hexToData(messageHex) else {
        die("sign: invalid hex input")
    }
    guard let privateKey = loadKey(label: KEY_LABEL) else {
        die("sign: key '\(KEY_LABEL)' not found in keychain (run 'init' first)")
    }
    var error: Unmanaged<CFError>?
    guard let sig = SecKeyCreateSignature(
        privateKey,
        .ecdsaSignatureMessageX962SHA256,
        message as CFData,
        &error
    ) as Data? else {
        if let err = error?.takeRetainedValue() {
            die("SecKeyCreateSignature failed: \(err)")
        }
        die("SecKeyCreateSignature failed (unknown error)")
    }
    guard let raw = derToRaw64(sig) else {
        die("derToRaw64 failed; DER hex: \(dataToHex(sig))")
    }
    print(dataToHex(raw))
}

func cmdPurge() {
    deleteKey(label: KEY_LABEL)
}

// MARK: - CLI dispatch

let args = CommandLine.arguments
guard args.count >= 2 else {
    die("""
        usage:
          \(args[0]) init  --pubkey-out PATH
          \(args[0]) sign  --hex MESSAGE_HEX
          \(args[0]) purge
        """, code: 2)
}

switch args[1] {
case "init":
    var pubkeyPath: String? = nil
    var i = 2
    while i < args.count {
        if args[i] == "--pubkey-out", i + 1 < args.count {
            pubkeyPath = args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }
    guard let path = pubkeyPath else {
        die("init: --pubkey-out PATH required", code: 2)
    }
    cmdInit(pubkeyPath: path)

case "sign":
    var hex: String? = nil
    var i = 2
    while i < args.count {
        if args[i] == "--hex", i + 1 < args.count {
            hex = args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }
    guard let h = hex else {
        die("sign: --hex MESSAGE_HEX required", code: 2)
    }
    cmdSign(messageHex: h)

case "purge":
    cmdPurge()

default:
    die("unknown subcommand: \(args[1])", code: 2)
}
