import SwiftUI
import CoreText

private let claudeTerracotta = Color(red: 0.85, green: 0.47, blue: 0.34)

struct SplashView: View {
    @State private var bgOpacity: Double = 0
    @State private var ccqOpacity: Double = 0
    @State private var expanded: Bool = false
    @State private var fontReady: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(bgOpacity)

            if fontReady {
                HStack(spacing: expanded ? 12 : 0) {
                    // C → CLAUDE
                    expandingWord(initial: "C", full: "CLAUDE", color: .white)
                    // C → CODE
                    expandingWord(initial: "C", full: "CODE", color: .white)
                    // Q → QUICK
                    expandingWord(initial: "Q", full: "QUICK", color: claudeTerracotta)
                }
                .opacity(ccqOpacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            registerFont()
            fontReady = true
            animate()
        }
    }

    private func expandingWord(initial: String, full: String, color: Color) -> some View {
        let suffix = String(full.dropFirst())
        let fontName = workbenchFontName()

        return HStack(spacing: 0) {
            Text(initial)
                .font(.custom(fontName, size: 48))
                .foregroundColor(color)

            if expanded {
                Text(suffix)
                    .font(.custom(fontName, size: 48))
                    .foregroundColor(color)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .clipped()
    }

    private func animate() {
        // Dark background
        withAnimation(.easeOut(duration: 0.5)) {
            bgOpacity = 0.8
        }

        // CCQ fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            ccqOpacity = 1
        }

        // CCQ → CLAUDE CODE QUICK
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(1.0)) {
            expanded = true
        }
    }

    private func registerFont() {
        guard let fontPath = Bundle.main.path(forResource: "Workbench", ofType: "ttf"),
              let fontData = NSData(contentsOfFile: fontPath),
              let provider = CGDataProvider(data: fontData),
              let cgFont = CGFont(provider) else {
            print("[CCQuick] Failed to load Workbench font file")
            return
        }

        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            if let err = error?.takeRetainedValue() {
                let desc = CFErrorCopyDescription(err) as String? ?? "unknown"
                // Ignore "already registered" errors
                if !desc.contains("already registered") {
                    print("[CCQuick] Font registration error: \(desc)")
                }
            }
        }
    }

    private func workbenchFontName() -> String {
        // Try different names the variable font might register as
        let candidates = ["WorkbenchEvenly-Regular", "Workbench", "WorkbenchEvenly", "Workbench-Regular"]
        for name in candidates {
            if let _ = NSFont(name: name, size: 12) {
                return name
            }
        }
        // Fallback — list all registered fonts containing "Workbench"
        let allFonts = NSFontManager.shared.availableFonts
        if let match = allFonts.first(where: { $0.contains("Workbench") }) {
            return match
        }
        return "Workbench"
    }
}
