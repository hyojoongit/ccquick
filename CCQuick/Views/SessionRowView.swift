import SwiftUI

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct SessionRowView: View {
    let session: ClaudeSession
    var sessionIndex: Int = 1   // 1-based, shows "#2" etc when > 1
    var totalForProject: Int = 1
    @State private var isHovered: Bool = false
    @State private var isPulsing: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Pulsing live indicator
            ZStack {
                // Pulse ring
                Circle()
                    .stroke(Color.green.opacity(isPulsing ? 0 : 0.3), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isPulsing ? 1.4 : 1.0)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.green.opacity(isHovered ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.green.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 13, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.projectName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Show session number when multiple for same project
                    if totalForProject > 1 {
                        Text("#\(sessionIndex)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.primary.opacity(0.5))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }

                    // Live pill
                    Text("LIVE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.12))
                        )
                }

                Text(abbreviatedPath(session.directory))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Duration + switch hint
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.duration)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                if isHovered {
                    Text("Click to switch")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.6))
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.green.opacity(0.04) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(isHovered ? Color.green.opacity(0.1) : Color.clear, lineWidth: 0.5)
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }

    private func abbreviatedPath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
