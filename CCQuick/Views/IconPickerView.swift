import SwiftUI

struct IconPickerView: View {
    let currentIcon: String
    let onSelect: (String?) -> Void
    let onCancel: () -> Void

    @State private var searchText: String = ""

    // Curated SF Symbols suitable for project icons
    private let icons: [(category: String, symbols: [String])] = [
        ("Projects", [
            "folder.fill", "folder.badge.gearshape", "doc.fill", "doc.text.fill",
            "tray.fill", "tray.2.fill", "archivebox.fill", "shippingbox.fill",
            "cube.fill", "cube.transparent.fill", "square.stack.3d.up.fill",
            "building.fill", "building.2.fill", "house.fill",
            "hammer.fill", "wrench.and.screwdriver.fill", "briefcase.fill",
            "paperclip", "latch.2.case.fill"
        ]),
        ("Code", [
            "chevron.left.forwardslash.chevron.right", "terminal.fill",
            "curlybraces", "number", "function", "textformat",
            "apple.terminal.fill", "text.word.spacing",
            "list.bullet.rectangle.fill", "command",
            "rectangle.and.text.magnifyingglass", "doc.plaintext.fill",
            "text.alignleft", "filemenu.and.selection",
            "parentheses", "ellipsis.curlybraces"
        ]),
        ("Design", [
            "paintbrush.fill", "paintbrush.pointed.fill", "paintpalette.fill",
            "pencil.tip", "pencil.tip.crop.circle.fill",
            "ruler.fill", "crop", "camera.fill", "camera.aperture",
            "photo.fill", "photo.artframe", "rectangle.3.group.fill",
            "sparkles", "wand.and.stars", "wand.and.rays",
            "eyedropper.full", "scribble.variable",
            "circle.hexagongrid.fill", "square.on.square.dashed"
        ]),
        ("Data & Infrastructure", [
            "externaldrive.fill", "server.rack", "cylinder.fill",
            "chart.bar.fill", "chart.line.uptrend.xyaxis", "chart.pie.fill",
            "tablecells.fill", "gauge.with.dots.needle.bottom.50percent",
            "cpu.fill", "memorychip.fill", "opticaldisc.fill",
            "internaldrive.fill", "opticaldiscdrive.fill",
            "arrow.triangle.branch", "point.3.connected.trianglepath.dotted",
            "square.grid.3x3.fill", "rectangle.split.3x3.fill"
        ]),
        ("Web & Network", [
            "globe", "globe.americas.fill", "globe.europe.africa.fill",
            "network", "antenna.radiowaves.left.and.right",
            "cloud.fill", "icloud.fill", "link", "link.circle.fill",
            "bolt.fill", "bolt.horizontal.fill", "wifi",
            "safari.fill", "at", "envelope.fill",
            "paperplane.fill", "bubble.left.fill", "bubble.left.and.bubble.right.fill"
        ]),
        ("Media", [
            "play.fill", "film.fill", "music.note",
            "headphones", "speaker.wave.3.fill", "mic.fill",
            "video.fill", "tv.fill", "display",
            "theatermasks.fill", "music.mic", "radio.fill"
        ]),
        ("Science & Math", [
            "atom", "waveform.path.ecg", "brain.head.profile",
            "testtube.2", "flask.fill", "staroflife.fill",
            "laurel.leading", "scope", "target",
            "plusminus", "sum", "x.squareroot"
        ]),
        ("Objects", [
            "star.fill", "heart.fill", "flag.fill",
            "bookmark.fill", "tag.fill", "bell.fill",
            "lightbulb.fill", "gearshape.fill", "gearshape.2.fill",
            "leaf.fill", "flame.fill", "drop.fill",
            "gamecontroller.fill", "puzzlepiece.fill", "trophy.fill",
            "crown.fill", "shield.fill", "lock.fill",
            "key.fill", "map.fill", "mappin.and.ellipse",
            "clock.fill", "hourglass", "stopwatch.fill",
            "gift.fill", "cart.fill", "bag.fill",
            "banknote.fill", "creditcard.fill", "dollarsign.circle.fill"
        ]),
        ("Arrows & Symbols", [
            "arrow.right.arrow.left", "arrow.up.arrow.down",
            "arrow.clockwise", "arrow.2.squarepath",
            "repeat", "shuffle", "infinity",
            "exclamationmark.triangle.fill", "checkmark.seal.fill",
            "xmark.octagon.fill", "questionmark.circle.fill",
            "info.circle.fill", "plus.circle.fill", "minus.circle.fill"
        ])
    ]

    private var filteredIcons: [(category: String, symbols: [String])] {
        if searchText.isEmpty { return icons }
        let query = searchText.lowercased()
        return icons.compactMap { category in
            let filtered = category.symbols.filter { $0.lowercased().contains(query) }
            return filtered.isEmpty ? nil : (category.category, filtered)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose Icon")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Button("Reset") {
                    onSelect(nil)
                }
                .font(.system(size: 12, design: .rounded))
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13))
                TextField("Search SF Symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider().opacity(0.3)

            // Icon grid
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(filteredIcons, id: \.category) { section in
                        Text(section.category)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                            ForEach(section.symbols, id: \.self) { symbol in
                                Button(action: { onSelect(symbol) }) {
                                    Image(systemName: symbol)
                                        .font(.system(size: 16))
                                        .foregroundColor(symbol == currentIcon ? .white : .primary.opacity(0.7))
                                        .frame(width: 38, height: 38)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(symbol == currentIcon ? Color.primary.opacity(0.8) : Color.primary.opacity(0.04))
                                        )
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding(16)
            }

            Divider().opacity(0.3)

            // Footer
            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 340, height: 420)
    }
}
