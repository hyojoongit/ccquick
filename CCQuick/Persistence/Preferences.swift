import Foundation
import Cocoa
import Carbon

// Key code to display name mapping
struct ShortcutKey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon modifier flags

    static let defaultShortcut = ShortcutKey(keyCode: 8, modifiers: UInt32(cmdKey | shiftKey)) // Cmd+Shift+C

    var displayName: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Cmd") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("Ctrl") }
        parts.append(keyName)
        return parts.joined(separator: " + ")
    }

    var symbolName: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("^") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(keyName)
        return parts.joined()
    }

    private var keyName: String {
        let names: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
            22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
            49: "Space", 36: "Return", 48: "Tab",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12"
        ]
        return names[keyCode] ?? "Key\(keyCode)"
    }

    static func carbonModifiers(from nsFlags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if nsFlags.contains(.command) { mods |= UInt32(cmdKey) }
        if nsFlags.contains(.shift) { mods |= UInt32(shiftKey) }
        if nsFlags.contains(.option) { mods |= UInt32(optionKey) }
        if nsFlags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}

enum TerminalType: String, Codable, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case iterm2 = "iTerm2"
    case warp = "Warp"

    var id: String { rawValue }

    var appName: String {
        switch self {
        case .terminal: return "Terminal"
        case .iterm2: return "iTerm"
        case .warp: return "Warp"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .terminal: return true // always available
        case .iterm2: return FileManager.default.fileExists(atPath: "/Applications/iTerm.app")
        case .warp: return FileManager.default.fileExists(atPath: "/Applications/Warp.app")
        }
    }
}

final class Preferences: ObservableObject, @unchecked Sendable {
    static let shared = Preferences()

    @Published var terminalType: TerminalType {
        didSet { UserDefaults.standard.set(terminalType.rawValue, forKey: "terminalType") }
    }

    @Published var claudePath: String {
        didSet { UserDefaults.standard.set(claudePath, forKey: "claudePath") }
    }

    @Published var scanDirectories: [String] {
        didSet { UserDefaults.standard.set(scanDirectories, forKey: "scanDirectories") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var scanDepth: Int {
        didSet { UserDefaults.standard.set(scanDepth, forKey: "scanDepth") }
    }

    @Published var shortcut: ShortcutKey {
        didSet {
            if let data = try? JSONEncoder().encode(shortcut) {
                UserDefaults.standard.set(data, forKey: "shortcut")
            }
            onShortcutChanged?(shortcut)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    var onShortcutChanged: ((ShortcutKey) -> Void)?

    private init() {
        let defaults = UserDefaults.standard
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        if let raw = defaults.string(forKey: "terminalType"),
           let t = TerminalType(rawValue: raw) {
            self.terminalType = t
        } else {
            self.terminalType = .terminal
        }

        self.claudePath = defaults.string(forKey: "claudePath") ?? "/opt/homebrew/bin/claude"

        if let dirs = defaults.stringArray(forKey: "scanDirectories") {
            self.scanDirectories = dirs
        } else {
            self.scanDirectories = [
                home + "/Desktop",
                home + "/Documents",
                home + "/Projects",
                home + "/Developer",
                home + "/work",
                home + "/repos",
                home + "/src"
            ]
        }

        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.scanDepth = defaults.object(forKey: "scanDepth") as? Int ?? 3
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")

        if let data = defaults.data(forKey: "shortcut"),
           let saved = try? JSONDecoder().decode(ShortcutKey.self, from: data) {
            self.shortcut = saved
        } else {
            self.shortcut = .defaultShortcut
        }
    }

    func detectClaudePath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path = path, !path.isEmpty {
            return path
        }
        return nil
    }

    private func updateLaunchAtLogin() {
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistPath = launchAgentsDir.appendingPathComponent("com.ccquick.app.plist")

        if launchAtLogin {
            // Find the app bundle path
            let appPath = Bundle.main.bundlePath

            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.ccquick.app</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>LaunchOnlyOnce</key>
                <true/>
            </dict>
            </plist>
            """

            try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try? plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
            print("[CCQuick] Launch agent installed at \(plistPath.path)")
        } else {
            try? FileManager.default.removeItem(at: plistPath)
            print("[CCQuick] Launch agent removed")
        }
    }
}
