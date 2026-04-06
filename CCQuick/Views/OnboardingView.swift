import SwiftUI
import Carbon

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)
private let claudeCoral = Color(red: 0.91, green: 0.52, blue: 0.36)
private let claudeSand = Color(red: 0.92, green: 0.72, blue: 0.45)

struct OnboardingView: View {
    @ObservedObject var prefs: Preferences
    var onComplete: () -> Void

    @State private var currentPage: Int = 0
    @State private var shortcutPressed: Bool = false

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content Pages

    private var contentView: some View {
        VStack(spacing: 0) {
            // Pages
            Group {
                switch currentPage {
                case 0: shortcutPage
                case 1: terminalPage
                case 2: permissionsPage
                case 3: readyPage
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentPage)

            // Bottom bar
            HStack {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == currentPage ? claudeTerracotta : Color.primary.opacity(0.12))
                            .frame(width: i == currentPage ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }

                Spacer()

                if currentPage < 3 {
                    let canProceed = currentPage != 2 || shortcutPressed
                    Button(action: {
                        guard canProceed else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 5) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(claudeTerracotta.opacity(canProceed ? 1 : 0.3))
                                .shadow(color: claudeTerracotta.opacity(canProceed ? 0.3 : 0), radius: 6, y: 2)
                        )
                    }
                    .buttonStyle(.borderless)
                    .opacity(canProceed ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.3), value: canProceed)
                } else {
                    Button(action: {
                        prefs.hasCompletedOnboarding = true
                        onComplete()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("Get Started")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(claudeTerracotta)
                                .shadow(color: claudeTerracotta.opacity(0.3), radius: 6, y: 2)
                        )
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Content Pages

    private var shortcutPage: some View {
        VStack(spacing: 18) {
            Spacer()

            // Animated keyboard icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(claudeTerracotta.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: "keyboard")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(claudeTerracotta)
            }

            Text("Your Shortcut")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("Summon the launcher\nfrom anywhere on your Mac")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Shortcut keys visual
            HStack(spacing: 4) {
                ForEach(shortcutKeys(), id: \.self) { key in
                    Text(key)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                                .shadow(color: Color.primary.opacity(0.05), radius: 2, y: 1)
                        )
                }
            }
            .padding(.top, 4)

            Text("Changeable in Settings")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary.opacity(0.5))

            Spacer()
        }
        .padding(32)
    }

    private var terminalPage: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(claudeTerracotta.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: "terminal")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(claudeTerracotta)
            }

            Text("Your Terminal")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("Claude Code opens in\nyour preferred terminal")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Terminal cards
            HStack(spacing: 12) {
                ForEach(TerminalType.allCases) { terminal in
                    terminalCard(terminal)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(32)
    }

    private func terminalCard(_ terminal: TerminalType) -> some View {
        let isSelected = prefs.terminalType == terminal
        let icon: String = {
            switch terminal {
            case .terminal: return "terminal"
            case .iterm2: return "rectangle.topthird.inset.filled"
            case .warp: return "bolt.horizontal"
            }
        }()

        return Button(action: { prefs.terminalType = terminal }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? claudeTerracotta : .secondary)

                Text(terminal.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .primary : .secondary)

                if !terminal.isInstalled {
                    Text("not found")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .frame(width: 90, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? claudeTerracotta.opacity(0.1) : Color.primary.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSelected ? claudeTerracotta.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.borderless)
    }

    private var permissionsPage: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(shortcutPressed ? Color.green.opacity(0.08) : claudeTerracotta.opacity(0.08))
                    .frame(width: 72, height: 72)

                Image(systemName: shortcutPressed ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(shortcutPressed ? .green : claudeTerracotta)
            }

            Text(shortcutPressed ? "You're all set!" : "Try Your Shortcut")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            if shortcutPressed {
                Text("Shortcut is working perfectly")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.green)
            } else {
                Text("Press the shortcut below to verify\nit works on your Mac")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Shortcut keys visual
            HStack(spacing: 4) {
                ForEach(shortcutKeys(), id: \.self) { key in
                    Text(key)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(shortcutPressed ? Color.green.opacity(0.08) : Color.primary.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(shortcutPressed ? Color.green.opacity(0.2) : Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                                .shadow(color: Color.primary.opacity(0.05), radius: 2, y: 1)
                        )
                }
            }
            .padding(.top, 4)

            if !shortcutPressed {
                Text("If a permission popup appears, click Allow")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.top, 4)
            }

            Spacer()
        }
        .padding(32)
        .onReceive(NotificationCenter.default.publisher(for: .ccquickHotkeyPressed)) { _ in
            if currentPage == 2 && !shortcutPressed {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    shortcutPressed = true
                }
            }
        }
        .onAppear {
            // Also trigger accessibility prompt if not yet granted
            if !Permissions.hasAccessibility {
                Permissions.requestAccessibility()
            }
        }
    }

    private var readyPage: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.green)
            }

            Text("Ready to Go")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            // Feature list
            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "keyboard", color: claudeTerracotta,
                          title: shortcutKeys().joined(separator: " "),
                          subtitle: "Open launcher")
                featureRow(icon: "arrow.down.doc", color: .blue,
                          title: "Drag & Drop",
                          subtitle: "Drop folders on menu bar")
                featureRow(icon: "bolt.fill", color: .green,
                          title: "Live Sessions",
                          subtitle: "Track & switch between sessions")
                featureRow(icon: "pin.fill", color: .orange,
                          title: "Pin Projects",
                          subtitle: "Keep favorites at the top")
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(32)
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func shortcutKeys() -> [String] {
        var keys: [String] = []
        let s = prefs.shortcut
        if s.modifiers & UInt32(cmdKey) != 0 { keys.append("\u{2318}") }
        if s.modifiers & UInt32(shiftKey) != 0 { keys.append("\u{21E7}") }
        if s.modifiers & UInt32(optionKey) != 0 { keys.append("\u{2325}") }
        if s.modifiers & UInt32(controlKey) != 0 { keys.append("\u{2303}") }

        let keyNames: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P",
            37: "L", 38: "J", 40: "K", 45: "N", 46: "M", 49: "Space"
        ]
        keys.append(keyNames[s.keyCode] ?? "?")
        return keys
    }

}
