import Foundation
import Cocoa

final class TerminalLaunchService: @unchecked Sendable {
    static let shared = TerminalLaunchService()
    private init() {}

    func launchClaude(in directory: String) {
        let prefs = Preferences.shared
        let escapedPath = directory
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let claudePath = prefs.claudePath

        let scriptSource: String
        switch prefs.terminalType {
        case .terminal:
            scriptSource = """
            tell application "Terminal"
                do script "cd \\"\(escapedPath)\\" && \(claudePath)"
                activate
            end tell
            """
        case .iterm2:
            scriptSource = """
            tell application "iTerm"
                activate
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text "cd \\"\(escapedPath)\\" && \(claudePath)"
                end tell
            end tell
            """
        case .warp:
            scriptSource = """
            tell application "Warp" to activate
            delay 0.5
            tell application "System Events"
                tell process "Warp"
                    set frontmost to true
                    delay 0.3
                    keystroke "cd \\"\(escapedPath)\\" && \(claudePath)"
                    key code 36
                end tell
            end tell
            """
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: scriptSource) {
                appleScript.executeAndReturnError(&error)
                if let error = error {
                    print("[CCQuick] AppleScript error: \(error)")
                }
            }
        }
    }
}
