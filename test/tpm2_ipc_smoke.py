#!/usr/bin/env python3
"""
tpm2_ipc_smoke.py — CI smoke test for the LL-044 TPM2-bound
signing path.

Connects to the running LavaLamp daemon at ~/.lavalamp/verify.sock,
sends a v4 IPC request, validates the 74-byte response shape +
freshness + ECDSA P-256 signature against the 33-byte SEC1-
compressed pubkey at ~/.lavalamp/verify.pub.

Assumes:
- The daemon was started after swtpm + tpm2-tools were set up.
- The TPM2TOOLS_TCTI env var was set when the daemon launched
  so its `tpm2_*` shell-outs go to swtpm.
- The daemon's startup banner reported "LL-044 TPM2-bound"
  (caller verifies this separately by grepping daemon stdout).

Exit code 0 on success; non-zero on any validation failure.
"""

import os
import socket
import struct
import sys
import time

try:
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature
    from cryptography.exceptions import InvalidSignature
except ImportError:
    print("ERROR: cryptography library missing (pip install cryptography)",
          file=sys.stderr)
    sys.exit(2)

IPC_VERSION = 0x04
IPC_REQUEST_LEN = 17
IPC_RESPONSE_LEN = 74
IPC_NONCE_LEN = 16
IPC_PUB_LEN = 33
IPC_TS_SKEW_S = 30


def main() -> int:
    home = os.path.expanduser("~")
    pub_path = os.path.join(home, ".lavalamp", "verify.pub")
    sock_path = os.path.join(home, ".lavalamp", "verify.sock")

    # 1. Read pubkey.
    with open(pub_path, "rb") as f:
        pub_raw = f.read()
    if len(pub_raw) != IPC_PUB_LEN:
        print(f"FAIL: pubkey length {len(pub_raw)}, expected {IPC_PUB_LEN}",
              file=sys.stderr)
        return 1
    if pub_raw[0] not in (0x02, 0x03):
        print(f"FAIL: pubkey prefix 0x{pub_raw[0]:02x}, expected 0x02 or 0x03",
              file=sys.stderr)
        return 1
    pub = ec.EllipticCurvePublicKey.from_encoded_point(
        ec.SECP256R1(), pub_raw)

    # 2. Send v4 request.
    nonce = os.urandom(IPC_NONCE_LEN)
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(sock_path)
    s.sendall(bytes([IPC_VERSION]) + nonce)

    # 3. Read response.
    resp = b""
    while len(resp) < IPC_RESPONSE_LEN:
        chunk = s.recv(IPC_RESPONSE_LEN - len(resp))
        if not chunk:
            break
        resp += chunk
    s.close()
    if len(resp) != IPC_RESPONSE_LEN:
        print(f"FAIL: response length {len(resp)}, expected {IPC_RESPONSE_LEN}",
              file=sys.stderr)
        return 1

    # 4. Parse fields.
    version = resp[0]
    result = resp[1]
    ts = struct.unpack("<q", resp[2:10])[0]
    sig_raw = resp[10:74]

    if version != IPC_VERSION:
        print(f"FAIL: response version 0x{version:02x}, expected 0x{IPC_VERSION:02x}",
              file=sys.stderr)
        return 1

    now = int(time.time())
    skew = abs(now - ts)
    if skew > IPC_TS_SKEW_S:
        print(f"FAIL: timestamp skew {skew}s > {IPC_TS_SKEW_S}s",
              file=sys.stderr)
        return 1

    # 5. Verify ECDSA P-256 signature.
    signed = nonce + bytes([result]) + resp[2:10]
    r = int.from_bytes(sig_raw[:32], "big")
    sval = int.from_bytes(sig_raw[32:], "big")
    sig_der = encode_dss_signature(r, sval)
    try:
        pub.verify(sig_der, signed, ec.ECDSA(hashes.SHA256()))
    except InvalidSignature:
        print("FAIL: ECDSA P-256 signature did not verify", file=sys.stderr)
        return 1

    # 6. Report.
    result_char = chr(result) if 0x20 <= result < 0x7f else f"\\x{result:02x}"
    print(f"PASS: v4 IPC end-to-end")
    print(f"  pubkey: 33-byte SEC1-compressed P-256, prefix 0x{pub_raw[0]:02x}")
    print(f"  result: '{result_char}' (0x{result:02x})")
    print(f"  timestamp: {ts}, skew {now - ts}s")
    print(f"  signature: 64-byte raw r||s, verified against pubkey")
    return 0


if __name__ == "__main__":
    sys.exit(main())
