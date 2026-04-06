import Cocoa
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, @unchecked Sendable {
    private var statusItem: NSStatusItem?
    var hotkeyService: HotkeyService?
    var panelController: LauncherPanelController?
    private let projectStore = ProjectStore()
    let sessionTracker = SessionTracker()
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var sessionObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupLauncherPanel()
        setupHotkey()
        sessionTracker.start()

        // Register as a Services provider
        NSApp.servicesProvider = self

        // Update menu bar badge when session count changes
        sessionObserver = sessionTracker.$sessions.sink { [weak self] sessions in
            self?.updateMenuBarBadge(count: sessions.count)
        }

        // Show onboarding on first launch
        if !Preferences.shared.hasCompletedOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showOnboarding()
            }
        }
    }

    private var splashWindow: NSWindow?

    private func showOnboarding() {
        // Phase 1: Fullscreen transparent splash
        showSplash {
            // Phase 2: After splash, show onboarding window
            self.showOnboardingWindow()
        }
    }

    private func showSplash(completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else { completion(); return }

        let splashView = SplashView()
        let hostingView = NSHostingView(rootView: splashView)

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.setFrame(screen.frame, display: true)

        window.alphaValue = 0
        window.orderFront(nil)

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            window.animator().alphaValue = 1
        }

        splashWindow = window

        // After splash animation plays, fade out and show onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.5
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.orderOut(nil)
                self.splashWindow = nil
                completion()
            })
        }
    }

    private func showOnboardingWindow() {
        let onboardingView = OnboardingView(prefs: Preferences.shared) { [weak self] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                self?.onboardingWindow?.animator().alphaValue = 0
            }, completionHandler: {
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
                // Open the launcher after onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self?.panelController?.showPanel()
                }
            })
        }
        let hostingView = NSHostingView(rootView: onboardingView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 440))
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true

        let blur = NSVisualEffectView(frame: container.bounds)
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]
        container.addSubview(blur)

        hostingView.frame = container.bounds
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)

        window.contentView = container
        window.center()
        window.isReleasedWhenClosed = false
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.4
            window.animator().alphaValue = 1
        }

        onboardingWindow = window
    }

    // MARK: - Open folder (Finder "Open With" / drag onto dock icon)

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                projectStore.recordOpen(path: url.path)
                TerminalLaunchService.shared.launchClaude(in: url.path)
            }
        }
    }

    // MARK: - Services ("Open with Claude Code" in Finder right-click > Services)

    @objc func openWithClaudeCode(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let items = pboard.pasteboardItems else { return }

        for item in items {
            if let urlString = item.string(forType: .fileURL),
               let url = URL(string: urlString) {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    projectStore.recordOpen(path: url.path)
                    TerminalLaunchService.shared.launchClaude(in: url.path)
                }
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let iconPath = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
               let icon = NSImage(contentsOfFile: iconPath) {
                icon.size = NSSize(width: 18, height: 18)
                icon.isTemplate = true
                button.image = icon
                button.imageScaling = .scaleProportionallyDown
            } else {
                button.image = NSImage(
                    systemSymbolName: "terminal.fill",
                    accessibilityDescription: "CCQuick"
                )
            }

            // Add drag & drop support
            setupDragDrop(on: button)
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }

    private func setupDragDrop(on button: NSStatusBarButton) {
        let dropView = StatusItemDropView(frame: button.bounds)
        dropView.autoresizingMask = [.width, .height]
        dropView.onDrop = { [weak self] path in
            self?.projectStore.recordOpen(path: path)
            TerminalLaunchService.shared.launchClaude(in: path)
        }
        button.addSubview(dropView)
    }

    private func rebuildMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.removeAllItems()

        // Open launcher
        let launcherItem = NSMenuItem(title: "Open Launcher", action: #selector(openLauncher), keyEquivalent: "l")
        launcherItem.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        menu.addItem(launcherItem)

        menu.addItem(NSMenuItem.separator())

        // Active sessions
        let sessions = sessionTracker.sessions
        if !sessions.isEmpty {
            let headerItem = NSMenuItem(title: "Active Sessions (\(sessions.count))", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            let headerAttr = NSMutableAttributedString(string: "Active Sessions ", attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ])
            headerAttr.append(NSAttributedString(string: "\(sessions.count)", attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
                .foregroundColor: NSColor.systemGreen
            ]))
            headerItem.attributedTitle = headerAttr
            menu.addItem(headerItem)

            for session in sessions {
                let sessionsForDir = sessions.filter { $0.directory == session.directory }
                let idx = sessionsForDir.firstIndex(where: { $0.id == session.id }).map { $0 + 1 } ?? 1
                let suffix = sessionsForDir.count > 1 ? " #\(idx)" : ""

                let item = NSMenuItem(
                    title: "\(session.projectName)\(suffix)  \(session.duration)",
                    action: #selector(focusSessionFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = session.id
                item.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
                item.image?.isTemplate = true

                let title = NSMutableAttributedString(string: session.projectName, attributes: [
                    .font: NSFont.systemFont(ofSize: 13, weight: .medium)
                ])
                if sessionsForDir.count > 1 {
                    title.append(NSAttributedString(string: " #\(idx)", attributes: [
                        .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ]))
                }
                title.append(NSAttributedString(string: "  \(session.duration)", attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]))
                item.attributedTitle = title

                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // Settings & Quit
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let replayItem = NSMenuItem(title: "Replay Onboarding", action: #selector(replayOnboarding), keyEquivalent: "")
        replayItem.image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil)
        menu.addItem(replayItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit CCQuick", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    private func setupLauncherPanel() {
        let viewModel = LauncherViewModel(store: projectStore, sessionTracker: sessionTracker)
        panelController = LauncherPanelController(viewModel: viewModel)
    }

    private func setupHotkey() {
        hotkeyService = HotkeyService()
        hotkeyService?.onHotkey = { [weak self] in
            // Don't open launcher if onboarding is showing
            // Don't open launcher if onboarding is visible
            if let w = self?.onboardingWindow, w.isVisible { return }
            self?.panelController?.togglePanel()
        }
        hotkeyService?.start()
    }

    @objc private func statusItemClicked() {
        // Menu will be shown by NSStatusItem automatically
    }

    @objc private func openLauncher() {
        panelController?.showPanel()
    }

    @objc private func focusSessionFromMenu(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int32,
              let session = sessionTracker.sessions.first(where: { $0.id == pid }) else { return }
        sessionTracker.focusSession(session)
    }

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(prefs: Preferences.shared)
        let hostingView = NSHostingView(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "CCQuick Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    private func updateMenuBarBadge(count: Int) {
        guard let button = statusItem?.button else { return }
        if count > 0 {
            button.title = " \(count)"
            button.imagePosition = .imageLeading
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        sessionTracker.scan()
        rebuildMenu()
    }

    @objc private func replayOnboarding() {
        showOnboarding()
    }

    @objc private func quitApp() {
        hotkeyService?.stop()
        sessionTracker.stop()
        NSApp.terminate(nil)
    }
}
