// LavaLamp menu bar app — daily-driver liveness indicator.
//
// Two-bit signal (strict LL-002 + LL-039 existence-only):
//   - Heartbeat file fresh (< 30 s old)  → green lavalamp icon
//   - Heartbeat file stale or missing    → grey-transparent lavalamp icon
//
// The app reads ONLY the heartbeat file's mtime; never the
// contents. The daemon writes only a timestamp to that file —
// nothing about the verify result, residue, λ values, or
// chaos-guard state ever traverses this channel. See
// LL-039 in LAVALAMP_SPEC.md for the cross-process channel
// specification + threat-model justification.
//
// Build:
//
//     swiftc -framework Cocoa lavalamp_menubar.swift -o lavalamp_menubar
//
// Run:
//
//     ./lavalamp_menubar
//
// Then start the daemon in another terminal:
//
//     julia --project=src/julia src/julia/daemon/lavalamp_daemon.jl
//
// The icon will go green within ~3 seconds (one heartbeat
// cadence), and stay green as long as the daemon is alive.

import Cocoa

// MARK: - Lavalamp icon procedural drawing

/// Draws an outline-style lavalamp icon (matching the line-art
/// reference designs) at the given size, in the given color
/// with the given alpha. Colour is baked into the image — the
/// caller swaps the entire NSImage on state change rather than
/// relying on contentTintColor (which doesn't reliably apply to
/// custom-drawn template images on NSStatusItem.button).
///
/// Path anatomy (22-pt viewbox):
///   - Cap (top): small trapezoid x=8..14 y=1..3, neck line at y=3
///   - Body: tall tapered curves from narrow top (x=8/14 at y=3)
///           to wider bottom (x=4/18 at y=15)
///   - Bubble: small circle in upper area at (14, 6) r=1
///   - Lava blob: wavy shape centred at (11, 11)
///   - Separator: horizontal line at y=15
///   - Base: trapezoid flaring outward x=4/18 (top) → x=2/20 (bottom)
///           y=15..21
func makeLavalampIcon(size: NSSize, color: NSColor) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        let w = rect.width
        let h = rect.height
        // Scale 22-unit viewbox coordinates to the target size.
        let sx: (CGFloat) -> CGFloat = { $0 / 22.0 * w }
        let sy: (CGFloat) -> CGFloat = { $0 / 22.0 * h }
        // AppKit y is flipped vs the design coordinates.
        let y: (CGFloat) -> CGFloat = { h - sy($0) }

        color.setStroke()
        let lineWidth: CGFloat = max(1.0, w / 22.0 * 1.4)

        // Outer outline (cap + body + base, as one continuous path):
        let outline = NSBezierPath()
        outline.lineWidth = lineWidth
        outline.lineCapStyle = .round
        outline.lineJoinStyle = .round

        // Cap (small trapezoid, narrower at top)
        outline.move(to: NSPoint(x: sx(9),  y: y(1)))
        outline.line(to: NSPoint(x: sx(13), y: y(1)))
        outline.line(to: NSPoint(x: sx(14), y: y(3)))
        outline.line(to: NSPoint(x: sx(8),  y: y(3)))
        outline.close()
        outline.stroke()

        // Body — tall tapering curves
        let body = NSBezierPath()
        body.lineWidth = lineWidth
        body.lineCapStyle = .round
        body.lineJoinStyle = .round
        body.move(to: NSPoint(x: sx(8),  y: y(3)))
        body.curve(to: NSPoint(x: sx(4), y: y(15)),
                   controlPoint1: NSPoint(x: sx(7), y: y(8)),
                   controlPoint2: NSPoint(x: sx(5), y: y(13)))
        body.line(to: NSPoint(x: sx(18), y: y(15)))
        body.curve(to: NSPoint(x: sx(14), y: y(3)),
                   controlPoint1: NSPoint(x: sx(17), y: y(13)),
                   controlPoint2: NSPoint(x: sx(15), y: y(8)))
        body.stroke()

        // Base trapezoid — flares outward at bottom
        let base = NSBezierPath()
        base.lineWidth = lineWidth
        base.lineCapStyle = .round
        base.lineJoinStyle = .round
        base.move(to: NSPoint(x: sx(4),  y: y(15)))
        base.line(to: NSPoint(x: sx(2),  y: y(21)))
        base.line(to: NSPoint(x: sx(20), y: y(21)))
        base.line(to: NSPoint(x: sx(18), y: y(15)))
        base.stroke()

        // Bubble — small circle in upper-right of body
        let bubble = NSBezierPath(ovalIn: NSRect(
            x: sx(13) - sx(0.9), y: y(6) - sy(0.9),
            width: sx(1.8), height: sy(1.8)))
        bubble.lineWidth = lineWidth
        bubble.stroke()

        // Lava blob — wavy shape in middle/lower body
        let blob = NSBezierPath()
        blob.lineWidth = lineWidth
        blob.lineCapStyle = .round
        blob.lineJoinStyle = .round
        blob.move(to: NSPoint(x: sx(9),  y: y(14)))
        blob.curve(to: NSPoint(x: sx(10), y: y(10)),
                   controlPoint1: NSPoint(x: sx(9.2), y: y(13)),
                   controlPoint2: NSPoint(x: sx(10.2), y: y(11.5)))
        blob.curve(to: NSPoint(x: sx(11), y: y(8)),
                   controlPoint1: NSPoint(x: sx(9.5), y: y(9)),
                   controlPoint2: NSPoint(x: sx(10.5), y: y(8)))
        blob.curve(to: NSPoint(x: sx(12), y: y(10)),
                   controlPoint1: NSPoint(x: sx(11.5), y: y(8)),
                   controlPoint2: NSPoint(x: sx(12.5), y: y(9)))
        blob.curve(to: NSPoint(x: sx(13), y: y(14)),
                   controlPoint1: NSPoint(x: sx(11.8), y: y(11.5)),
                   controlPoint2: NSPoint(x: sx(12.8), y: y(13)))
        blob.line(to: NSPoint(x: sx(9), y: y(14)))
        blob.close()
        blob.stroke()

        return true
    }
    // Don't mark as template — we're baking colour into the image.
    image.isTemplate = false
    return image
}

// MARK: - App delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var pollTimer: Timer?

    // Pre-rendered images for each state. Image is swapped on
    // state change (not contentTintColor) because contentTintColor
    // doesn't reliably apply to custom-drawn images on the
    // NSStatusItem.button — colour is baked into the image.
    var iconActive: NSImage!
    var iconInactive: NSImage!

    let heartbeatPath: String = NSString(string: "~/.lavalamp/heartbeat")
        .expandingTildeInPath
    let staleThreshold: TimeInterval = 30.0
    let pollInterval: TimeInterval = 2.0

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength)

        let iconSize = NSSize(width: 18, height: 18)
        // Active: vibrant green at full opacity.
        iconActive = makeLavalampIcon(
            size: iconSize, color: NSColor.systemGreen)
        // Inactive: system label colour (auto-adapts to light/dark
        // mode) at very low alpha — outline still legible but
        // clearly reads as "off / disabled" per macOS conventions.
        iconInactive = makeLavalampIcon(
            size: iconSize,
            color: NSColor.labelColor.withAlphaComponent(0.25))

        statusItem.button?.image = iconInactive

        // Build a small dropdown menu with Quit.
        let menu = NSMenu()

        let statusHeader = NSMenuItem(title: "LavaLamp",
                                       action: nil, keyEquivalent: "")
        statusHeader.isEnabled = false
        menu.addItem(statusHeader)

        let stateItem = NSMenuItem(title: "  (checking ...)",
                                    action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        stateItem.tag = 1   // we'll find this by tag to update title
        menu.addItem(stateItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Quit lavalamp_menubar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu

        // First update + start polling.
        updateState()
        pollTimer = Timer.scheduledTimer(
            withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
                self?.updateState()
            }
    }

    /// Reads heartbeat-file mtime; swaps icon image + updates menu state.
    /// Reveals only liveness — never the file's contents.
    func updateState() {
        let alive = isHeartbeatFresh()
        guard let button = statusItem.button else { return }

        if alive {
            button.image = iconActive
            button.toolTip = "LavaLamp is securing identity"
        } else {
            button.image = iconInactive
            button.toolTip = "LavaLamp is not running"
        }

        // Update the dropdown menu's state line.
        if let stateItem = statusItem.menu?.item(withTag: 1) {
            stateItem.title = alive ? "  ● Active" : "  ○ Stopped"
        }
    }

    func isHeartbeatFresh() -> Bool {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: heartbeatPath),
              let mtime = attrs[.modificationDate] as? Date else {
            return false
        }
        return Date().timeIntervalSince(mtime) < staleThreshold
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory = no Dock icon, no main menu — runs as a pure
// menu-bar agent.
app.setActivationPolicy(.accessory)
app.run()
