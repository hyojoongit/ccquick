import Cocoa

final class HighlightBorderView: NSView {
    private let claudeTerracotta = NSColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1.0)

    override var wantsLayer: Bool {
        get { true }
        set {}
    }

    override func layout() {
        super.layout()
        setupLayers()
    }

    private func setupLayers() {
        layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        layer?.cornerRadius = 10
        layer?.masksToBounds = true

        let rect = bounds

        // Inner glow gradient from all edges — fades from terracotta to transparent toward center
        // Top edge
        addEdgeGlow(frame: CGRect(x: 0, y: rect.height - 40, width: rect.width, height: 40),
                     startPoint: CGPoint(x: 0.5, y: 1), endPoint: CGPoint(x: 0.5, y: 0))
        // Bottom edge
        addEdgeGlow(frame: CGRect(x: 0, y: 0, width: rect.width, height: 40),
                     startPoint: CGPoint(x: 0.5, y: 0), endPoint: CGPoint(x: 0.5, y: 1))
        // Left edge
        addEdgeGlow(frame: CGRect(x: 0, y: 0, width: 40, height: rect.height),
                     startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5))
        // Right edge
        addEdgeGlow(frame: CGRect(x: rect.width - 40, y: 0, width: 40, height: rect.height),
                     startPoint: CGPoint(x: 1, y: 0.5), endPoint: CGPoint(x: 0, y: 0.5))

        // Corner radial glows for extra warmth at corners
        let cornerSize: CGFloat = 80
        addCornerGlow(center: CGPoint(x: 0, y: rect.height), size: cornerSize)           // top-left
        addCornerGlow(center: CGPoint(x: rect.width, y: rect.height), size: cornerSize)   // top-right
        addCornerGlow(center: CGPoint(x: 0, y: 0), size: cornerSize)                       // bottom-left
        addCornerGlow(center: CGPoint(x: rect.width, y: 0), size: cornerSize)              // bottom-right
    }

    private func addEdgeGlow(frame: CGRect, startPoint: CGPoint, endPoint: CGPoint) {
        let gradient = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = [
            claudeTerracotta.withAlphaComponent(0.5).cgColor,
            claudeTerracotta.withAlphaComponent(0.15).cgColor,
            NSColor.clear.cgColor
        ]
        gradient.locations = [0, 0.4, 1]
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        layer?.addSublayer(gradient)
    }

    private func addCornerGlow(center: CGPoint, size: CGFloat) {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.frame = CGRect(x: center.x - size, y: center.y - size, width: size * 2, height: size * 2)
        gradient.colors = [
            claudeTerracotta.withAlphaComponent(0.45).cgColor,
            claudeTerracotta.withAlphaComponent(0.1).cgColor,
            NSColor.clear.cgColor
        ]
        gradient.locations = [0, 0.4, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer?.addSublayer(gradient)
    }
}
