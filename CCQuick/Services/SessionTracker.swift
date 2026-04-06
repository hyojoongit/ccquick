import Foundation
import Cocoa

enum SessionTerminal: String, Hashable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"
    case warp = "Warp"
    case tmux = "tmux"
    case unknown = "Unknown"
}

struct ClaudeSession: Identifiable, Hashable {
    let id: Int32  // PID
    let directory: String
    let projectName: String
    let startTime: Date
    let tty: String
    let terminal: SessionTerminal

    var duration: String {
        let elapsed = Date().timeIntervalSince(startTime)
        let mins = Int(elapsed) / 60
        let hours = mins / 60
        if hours > 0 {
            return "\(hours)h \(mins % 60)m"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "<1m"
        }
    }
}

final class SessionTracker: ObservableObject, @unchecked Sendable {
    @Published var sessions: [ClaudeSession] = []
    private var timer: Timer?
    private var knownStartTimes: [Int32: Date] = [:]
    private var highlightOverlay: NSWindow?

    func start() {
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scan()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    var activeCount: Int {
        sessions.count
    }

    func scan() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let found = self.findClaudeSessions()
            DispatchQueue.main.async {
                self.sessions = found
            }
        }
    }

    func focusSession(_ session: ClaudeSession) {
        let tty = session.tty

        // Step 1: Use AppleScript to find the right window and set it to index 1,
        //         but do NOT activate the app (which brings all windows)
        let orderScript: String
        switch session.terminal {
        case .terminal:
            orderScript = """
            tell application "Terminal"
                set targetTTY to "/dev/\(tty)"
                repeat with w in windows
                    repeat with t in tabs of w
                        if tty of t is targetTTY then
                            set selected tab of w to t
                            set index of w to 1
                        end if
                    end repeat
                end repeat
            end tell
            """
        case .iterm2:
            orderScript = """
            tell application "iTerm2"
                set targetTTY to "/dev/\(tty)"
                repeat with w in windows
                    repeat with t in tabs of w
                        repeat with s in sessions of t
                            if tty of s is targetTTY then
                                select s
                                set index of w to 1
                            end if
                        end repeat
                    end repeat
                end repeat
            end tell
            """
        case .tmux:
            orderScript = ""
        case .warp, .unknown:
            orderScript = ""
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Execute the window ordering script first
            if !orderScript.isEmpty {
                var error: NSDictionary?
                if let script = NSAppleScript(source: orderScript) {
                    script.executeAndReturnError(&error)
                    if let error = error {
                        print("[CCQuick] Order script error: \(error)")
                    }
                }
            }

            // Step 2: Raise just the frontmost window using Accessibility API
            DispatchQueue.main.async {
                self?.raiseTargetWindow(for: session)
            }
        }
    }

    private func raiseTargetWindow(for session: ClaudeSession) {
        let bundleID: String
        switch session.terminal {
        case .terminal: bundleID = "com.apple.Terminal"
        case .iterm2: bundleID = "com.googlecode.iterm2"
        case .warp: bundleID = "dev.warp.Warp-Stable"
        case .tmux: bundleID = "com.googlecode.iterm2"
        case .unknown: bundleID = "com.apple.Terminal"
        }

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return
        }

        // Use Accessibility to raise just window 1
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)

        if let windows = windowsRef as? [AXUIElement], let firstWindow = windows.first {
            AXUIElementPerformAction(firstWindow, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(firstWindow, kAXFocusedAttribute as CFString, true as CFTypeRef)
        }

        // Bring app to front without raising all windows
        app.activate()

        // Flash highlight border around the window
        flashWindowHighlight(for: session, app: app)
    }

    private func flashWindowHighlight(for session: ClaudeSession, app: NSRunningApplication) {
        // Use CGWindowListCopyWindowInfo to get the frontmost window bounds
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

        let pid = app.processIdentifier
        // Find the first on-screen window for this app
        guard let windowInfo = windowList.first(where: {
            ($0[kCGWindowOwnerPID as String] as? Int32) == pid &&
            ($0[kCGWindowLayer as String] as? Int) == 0  // normal window layer
        }),
        let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
        let x = boundsDict["X"],
        let y = boundsDict["Y"],
        let w = boundsDict["Width"],
        let h = boundsDict["Height"] else { return }

        // CG coordinates: top-left origin. Convert to NSWindow bottom-left origin.
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        let flippedY = primaryScreenHeight - y - h

        let windowFrame = NSRect(x: x, y: flippedY, width: w, height: h)

        // Clean up any previous overlay
        highlightOverlay?.orderOut(nil)
        highlightOverlay = nil

        // Create overlay window
        let overlay = NSWindow(
            contentRect: windowFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        overlay.isOpaque = false
        overlay.backgroundColor = .clear
        overlay.level = .floating
        overlay.ignoresMouseEvents = true
        overlay.isReleasedWhenClosed = false
        overlay.hasShadow = false

        let borderView = HighlightBorderView(frame: NSRect(origin: .zero, size: windowFrame.size))
        overlay.contentView = borderView

        // Keep a strong reference
        highlightOverlay = overlay

        overlay.alphaValue = 0
        overlay.orderFront(nil)

        // Animate: quick fade in, brief hold, gentle fade out
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            overlay.animator().alphaValue = 1
        }, completionHandler: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 0.6
                    ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    overlay.animator().alphaValue = 0
                }, completionHandler: {
                    overlay.orderOut(nil)
                    self?.highlightOverlay = nil
                })
            }
        })
    }

    private func findClaudeSessions() -> [ClaudeSession] {
        // Find claude PIDs, cwds, TTYs, and which terminal app owns them
        let shellCmd = """
        ps -eo pid,tty,comm | awk '$3 == "claude" {print $1, $2}' | while read pid tty; do
            cwd=$(lsof -p "$pid" -a -d cwd 2>/dev/null | awk '/cwd/{print $NF}')
            [ -z "$cwd" ] || [ "$cwd" = "/" ] && cwd="unknown"

            # Trace parent chain to find terminal app
            term="unknown"
            p=$pid
            for i in 1 2 3 4 5 6 7 8; do
                p=$(ps -p "$p" -o ppid= 2>/dev/null | tr -d ' ')
                [ -z "$p" ] || [ "$p" = "1" ] || [ "$p" = "0" ] && break
                pcomm=$(ps -p "$p" -o comm= 2>/dev/null)
                case "$pcomm" in
                    *iTerm*) term="iterm2"; break ;;
                    *Terminal*) term="terminal"; break ;;
                    *Warp*) term="warp"; break ;;
                    *tmux*) term="tmux"; break ;;
                esac
            done
            echo "$pid:$tty:$term:$cwd"
        done
        """

        let output = runShell(shellCmd)
        guard !output.isEmpty else { return [] }

        var results: [ClaudeSession] = []
        let now = Date()

        for line in output.split(separator: "\n") {
            let str = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            // Format: pid:tty:terminal:cwd
            let parts = str.split(separator: ":", maxSplits: 3)
            guard parts.count == 4,
                  let pid = Int32(parts[0]) else { continue }

            let tty = String(parts[1])
            let termStr = String(parts[2])
            let dir = String(parts[3])

            let terminal: SessionTerminal
            switch termStr {
            case "iterm2": terminal = .iterm2
            case "terminal": terminal = .terminal
            case "warp": terminal = .warp
            case "tmux": terminal = .tmux
            default: terminal = .unknown
            }

            let projectName: String
            let directory: String
            if dir == "unknown" || dir == "/" {
                directory = "Unknown"
                projectName = "Claude"
            } else {
                directory = dir
                projectName = URL(fileURLWithPath: dir).lastPathComponent
            }

            let startTime = knownStartTimes[pid] ?? now
            knownStartTimes[pid] = startTime

            results.append(ClaudeSession(
                id: pid,
                directory: directory,
                projectName: projectName,
                startTime: startTime,
                tty: tty,
                terminal: terminal
            ))
        }

        // Clean up stale start times
        let activePIDs = Set(results.map(\.id))
        knownStartTimes = knownStartTimes.filter { activePIDs.contains($0.key) }

        return results
    }

    private func runShell(_ command: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
