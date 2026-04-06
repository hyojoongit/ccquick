import SwiftUI
import Carbon

struct SettingsView: View {
    @ObservedObject var prefs: Preferences
    @State private var newScanDir: String = ""
    @State private var showDirPicker: Bool = false
    @State private var isRecordingShortcut: Bool = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            scanTab
                .tabItem {
                    Label("Scan", systemImage: "magnifyingglass")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 460, height: 340)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section {
                Picker("Terminal App", selection: $prefs.terminalType) {
                    ForEach(TerminalType.allCases) { terminal in
                        HStack {
                            Text(terminal.rawValue)
                            if !terminal.isInstalled {
                                Text("(not found)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .tag(terminal)
                    }
                }

                HStack {
                    TextField("Claude CLI Path", text: $prefs.claudePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Button("Detect") {
                        if let path = prefs.detectClaudePath() {
                            prefs.claudePath = path
                        }
                    }
                    .font(.system(size: 12))
                }
            } header: {
                Text("Terminal")
            }

            Section {
                HStack {
                    Text("Shortcut")
                    Spacer()

                    if isRecordingShortcut {
                        ZStack {
                            ShortcutRecorderView(shortcut: $prefs.shortcut, isRecording: $isRecordingShortcut)
                                .frame(width: 0, height: 0)
                                .opacity(0)

                            Text("Press shortcut...")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(Color.accentColor.opacity(0.08))
                                        )
                                )
                        }
                    } else {
                        Button(action: { isRecordingShortcut = true }) {
                            Text(prefs.shortcut.displayName)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.borderless)
                    }

                    if prefs.shortcut != .defaultShortcut {
                        Button(action: { prefs.shortcut = .defaultShortcut }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Toggle("Launch at Login", isOn: $prefs.launchAtLogin)
            } header: {
                Text("General")
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    // MARK: - Scan

    private var scanTab: some View {
        Form {
            Section {
                Stepper("Scan Depth: \(prefs.scanDepth)", value: $prefs.scanDepth, in: 1...6)

                List {
                    ForEach(prefs.scanDirectories, id: \.self) { dir in
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(abbreviatePath(dir))
                                .font(.system(size: 12, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button(action: {
                                prefs.scanDirectories.removeAll { $0 == dir }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(height: 140)

                HStack {
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = true
                        panel.message = "Select directories to scan for projects"
                        if panel.runModal() == .OK {
                            for url in panel.urls {
                                let path = url.path
                                if !prefs.scanDirectories.contains(path) {
                                    prefs.scanDirectories.append(path)
                                }
                            }
                        }
                    }) {
                        Label("Add Directory...", systemImage: "plus")
                            .font(.system(size: 12))
                    }

                    Spacer()
                }
            } header: {
                Text("Scan Directories")
            } footer: {
                Text("CCQuick scans these directories for git repositories on launch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    // MARK: - About

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Spacer()

            if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
               let nsImage = NSImage(contentsOfFile: iconPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }

            Text("CCQuick")
                .font(.system(size: 20, weight: .semibold, design: .rounded))

            Text("Quick access to Claude Code")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Text("Version 1.0")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// MARK: - Shortcut Recorder

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: ShortcutKey
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onShortcutCaptured = { keyCode, modifiers in
            shortcut = ShortcutKey(keyCode: UInt32(keyCode), modifiers: ShortcutKey.carbonModifiers(from: modifiers))
            isRecording = false
        }
        view.onCancel = {
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        if isRecording {
            nsView.startRecording()
        }
    }
}

final class ShortcutRecorderNSView: NSView {
    var onShortcutCaptured: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?

    func startRecording() {
        // Remove old monitor
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.stopRecording()
                self?.onCancel?()
                return nil
            }
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // Require at least one modifier
            if !mods.isEmpty {
                self?.onShortcutCaptured?(event.keyCode, mods)
                self?.stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stopRecording()
    }
}
