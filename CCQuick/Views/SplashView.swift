import SwiftUI
import CoreText

private let claudeRed = Color(red: 0.89, green: 0.27, blue: 0.15)

struct SplashView: View {
    @State private var bgOpacity: Double = 0
    @State private var ccqOpacity: Double = 0
    @State private var expanded: Bool = false
    @State private var fontReady: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity)

            if fontReady {
                HStack(spacing: expanded ? 10 : 0) {
                    expandingWord(initial: "C", full: "CLAUDE", color: .white)
                    expandingWord(initial: "C", full: "CODE", color: .white)
                    expandingWord(initial: "Q", full: "QUICK", color: claudeRed)
                }
                .opacity(ccqOpacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            registerFont()
            fontReady = true

            withAnimation(.easeOut(duration: 0.5)) {
                bgOpacity = 0.8
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                ccqOpacity = 1
            }

            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(1.0)) {
                expanded = true
            }
        }
    }

    private func expandingWord(initial: String, full: String, color: Color) -> some View {
        let suffix = String(full.dropFirst())
        let fontName = dmSerifFontName()

        return HStack(spacing: 0) {
            Text(initial)
                .font(.custom(fontName, size: 56))
                .italic()
                .foregroundColor(color)

            if expanded {
                Text(suffix)
                    .font(.custom(fontName, size: 56))
                    .italic()
                    .foregroundColor(color)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .clipped()
    }

    private func registerFont() {
        guard let fontPath = Bundle.main.path(forResource: "DMSerifDisplay-Italic", ofType: "ttf"),
              let fontData = NSData(contentsOfFile: fontPath),
              let provider = CGDataProvider(data: fontData),
              let cgFont = CGFont(provider) else { return }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(cgFont, &error)
    }

    private func dmSerifFontName() -> String {
        let candidates = ["DMSerifDisplay-Italic", "DM Serif Display", "DMSerifDisplay"]
        for name in candidates {
            if let _ = NSFont(name: name, size: 12) {
                return name
            }
        }
        let allFonts = NSFontManager.shared.availableFonts
        if let match = allFonts.first(where: { $0.contains("DMSerif") }) {
            return match
        }
        return "Georgia"
    }
}
