import SwiftUI

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct DirectoryRowView: View {
    let project: Project
    let isSelected: Bool
    var onTogglePin: (() -> Void)? = nil
    var onChangeIcon: (() -> Void)? = nil
    @State private var isHovered: Bool = false
    @State private var iconHovered: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Project icon pill — click to change icon
            Button(action: { onChangeIcon?() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            isSelected
                                ? Color.white.opacity(iconHovered ? 0.25 : 0.15)
                                : Color.primary.opacity(iconHovered ? 0.12 : (isHovered ? 0.08 : 0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    isSelected
                                        ? Color.white.opacity(iconHovered ? 0.35 : 0.2)
                                        : Color.primary.opacity(iconHovered ? 0.15 : 0.08),
                                    lineWidth: 0.5
                                )
                        )
                        .frame(width: 32, height: 32)

                    ZStack {
                        Image(systemName: project.displayIcon)
                            .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
                            .font(.system(size: 14, weight: .medium))
                            .opacity(iconHovered ? 0.3 : 1)

                        if iconHovered {
                            Image(systemName: "pencil")
                                .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                                .font(.system(size: 12, weight: .semibold))
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: iconHovered)
                }
            }
            .buttonStyle(.borderless)
            .onHover { h in iconHovered = h }

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                Text(abbreviatedPath(project.path))
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let date = project.lastOpened {
                Text(relativeDate(date))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary)
            }

            // Pin — appears on hover or if pinned
            if isHovered || isSelected || project.isPinned {
                Button(action: { onTogglePin?() }) {
                    Image(systemName: project.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(
                            isSelected ? .white.opacity(0.8)
                            : (project.isPinned ? claudeTerracotta : .secondary)
                        )
                        .frame(width: 22, height: 22)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(isHovered && !isSelected ? 0.04 : 0))
                        )
                }
                .buttonStyle(.borderless)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 2)
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isHovered = hovering
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

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
