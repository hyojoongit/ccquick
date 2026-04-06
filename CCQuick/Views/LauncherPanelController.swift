import Cocoa
import SwiftUI

final class LauncherPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.hidesOnDeactivate = true
        self.isReleasedWhenClosed = false
        self.animationBehavior = .utilityWindow
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true

        if let contentView = self.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 16
            contentView.layer?.masksToBounds = true
            // Subtle outer glow
            contentView.shadow = NSShadow()
            contentView.layer?.shadowColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
            contentView.layer?.shadowOffset = CGSize(width: 0, height: -2)
            contentView.layer?.shadowRadius = 20
            contentView.layer?.shadowOpacity = 1
        }
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.panelController?.hidePanel()
    }
}

// Fullscreen blurred dimming overlay with aurora animation
final class DimmingWindow: NSWindow {
    private var auroraLayer1: CAGradientLayer?
    private var auroraLayer2: CAGradientLayer?
    private var auroraLayer3: CAGradientLayer?

    init() {
        super.init(
            contentRect: NSRect.zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.ignoresMouseEvents = false
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Base blur layer
        let blur = NSVisualEffectView()
        blur.material = .fullScreenUI
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.appearance = NSAppearance(named: .vibrantDark)
        blur.alphaValue = 0.5
        blur.wantsLayer = true
        self.contentView = blur
    }

    override var canBecomeKey: Bool { false }

    override func mouseDown(with event: NSEvent) {
        (NSApp.delegate as? AppDelegate)?.panelController?.hidePanel()
    }

    func startAurora() {
        guard let layer = contentView?.layer else { return }

        // Remove old layers
        auroraLayer1?.removeFromSuperlayer()
        auroraLayer2?.removeFromSuperlayer()
        auroraLayer3?.removeFromSuperlayer()

        let bounds = layer.bounds

        // Aurora blob 1 — soft terracotta
        let a1 = makeAuroraBlob(
            colors: [
                NSColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 0.15).cgColor,
                NSColor(red: 0.91, green: 0.52, blue: 0.36, alpha: 0.06).cgColor,
                NSColor.clear.cgColor
            ],
            bounds: bounds,
            size: CGSize(width: bounds.width * 0.7, height: bounds.height * 0.7)
        )
        layer.addSublayer(a1)
        auroraLayer1 = a1
        animateBlob(a1, bounds: bounds, duration: 14, dx: 0.15, dy: 0.1)

        // Aurora blob 2 — faint warm sand
        let a2 = makeAuroraBlob(
            colors: [
                NSColor(red: 0.92, green: 0.72, blue: 0.45, alpha: 0.10).cgColor,
                NSColor(red: 0.88, green: 0.65, blue: 0.38, alpha: 0.04).cgColor,
                NSColor.clear.cgColor
            ],
            bounds: bounds,
            size: CGSize(width: bounds.width * 0.6, height: bounds.height * 0.6)
        )
        layer.addSublayer(a2)
        auroraLayer2 = a2
        animateBlob(a2, bounds: bounds, duration: 17, dx: -0.12, dy: 0.15)

        // Aurora blob 3 — subtle sienna
        let a3 = makeAuroraBlob(
            colors: [
                NSColor(red: 0.72, green: 0.32, blue: 0.25, alpha: 0.10).cgColor,
                NSColor(red: 0.60, green: 0.25, blue: 0.20, alpha: 0.04).cgColor,
                NSColor.clear.cgColor
            ],
            bounds: bounds,
            size: CGSize(width: bounds.width * 0.55, height: bounds.height * 0.55)
        )
        layer.addSublayer(a3)
        auroraLayer3 = a3
        animateBlob(a3, bounds: bounds, duration: 18, dx: 0.1, dy: -0.14)
    }

    func stopAurora() {
        auroraLayer1?.removeAllAnimations()
        auroraLayer2?.removeAllAnimations()
        auroraLayer3?.removeAllAnimations()
        auroraLayer1?.removeFromSuperlayer()
        auroraLayer2?.removeFromSuperlayer()
        auroraLayer3?.removeFromSuperlayer()
        auroraLayer1 = nil
        auroraLayer2 = nil
        auroraLayer3 = nil
    }

    private func makeAuroraBlob(colors: [CGColor], bounds: CGRect, size: CGSize) -> CAGradientLayer {
        let blob = CAGradientLayer()
        blob.type = .radial
        blob.colors = colors
        blob.locations = [0, 0.5, 1]
        blob.startPoint = CGPoint(x: 0.5, y: 0.5)
        blob.endPoint = CGPoint(x: 1, y: 1)
        blob.frame = CGRect(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
        blob.cornerRadius = min(size.width, size.height) / 2
        return blob
    }

    private func animateBlob(_ blob: CAGradientLayer, bounds: CGRect, duration: Double, dx: CGFloat, dy: CGFloat) {
        // Slow drifting movement
        let move = CAKeyframeAnimation(keyPath: "position")
        let cx = bounds.midX
        let cy = bounds.midY
        let rx = bounds.width * dx
        let ry = bounds.height * dy
        move.values = [
            NSValue(point: NSPoint(x: cx, y: cy)),
            NSValue(point: NSPoint(x: cx + rx, y: cy + ry)),
            NSValue(point: NSPoint(x: cx - rx * 0.5, y: cy + ry * 1.2)),
            NSValue(point: NSPoint(x: cx - rx, y: cy - ry * 0.5)),
            NSValue(point: NSPoint(x: cx + rx * 0.3, y: cy - ry)),
            NSValue(point: NSPoint(x: cx, y: cy))
        ]
        move.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        move.duration = duration
        move.repeatCount = .infinity
        move.timingFunction = CAMediaTimingFunction(name: .linear)
        move.isRemovedOnCompletion = false
        blob.add(move, forKey: "drift")

        // Slow pulsing scale
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.92
        scale.toValue = 1.1
        scale.duration = duration * 0.6
        scale.autoreverses = true
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        scale.isRemovedOnCompletion = false
        blob.add(scale, forKey: "pulse")

        // Slow opacity breathing
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.7
        fade.toValue = 1.0
        fade.duration = duration * 0.4
        fade.autoreverses = true
        fade.repeatCount = .infinity
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fade.isRemovedOnCompletion = false
        blob.add(fade, forKey: "breathe")
    }
}

final class LauncherPanelController: @unchecked Sendable {
    private var panel: LauncherPanel?
    private var dimmingWindow: DimmingWindow?
    let viewModel: LauncherViewModel
    private var monitor: Any?
    private var clickMonitor: Any?
    private var localClickMonitor: Any?

    init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    func showPanel() {
        if panel == nil {
            createPanel()
        }
        guard let panel = panel, let screen = NSScreen.main else { return }

        viewModel.searchText = ""
        viewModel.resetSelection()

        // Show dimming overlay across the full screen
        if dimmingWindow == nil {
            dimmingWindow = DimmingWindow()
        }
        dimmingWindow?.setFrame(screen.frame, display: true)
        dimmingWindow?.alphaValue = 0
        dimmingWindow?.orderFront(nil)

        let screenFrame = screen.visibleFrame
        let panelWidth: CGFloat = 560
        let panelHeight: CGFloat = 460
        let x = screenFrame.midX - panelWidth / 2
        let y = screenFrame.midY - panelHeight / 2 + 120

        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            dimmingWindow?.animator().alphaValue = 1
        }

        dimmingWindow?.startAurora()

        // Click outside panel to dismiss (both global and local)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            self.hidePanel()
        }
        // Local monitor catches clicks on the dimming window (which is part of our app)
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return event }
            // If the click is NOT inside the panel, dismiss
            let clickWindow = event.window
            if clickWindow !== panel {
                self.hidePanel()
                return nil
            }
            return event
        }

        // Keyboard navigation
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            switch event.keyCode {
            case 53: // Escape
                self.hidePanel()
                return nil
            case 126: // Up
                self.viewModel.moveSelectionUp()
                return nil
            case 125: // Down
                self.viewModel.moveSelectionDown()
                return nil
            case 48: // Tab
                self.viewModel.moveSelectionDown()
                return nil
            default:
                return event
            }
        }
    }

    func hidePanel() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        if let clickMonitor = clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        if let localClickMonitor = localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        guard let panel = panel else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            self.dimmingWindow?.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            self.dimmingWindow?.stopAurora()
            self.dimmingWindow?.orderOut(nil)
        })
    }

    func togglePanel() {
        if let panel = panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func createPanel() {
        let panel = LauncherPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 460))

        viewModel.onDismiss = { [weak self] in
            self?.hidePanel()
        }

        let hostView = NSHostingView(rootView: LauncherView(viewModel: viewModel))
        panel.contentView = hostView

        self.panel = panel
    }
}
