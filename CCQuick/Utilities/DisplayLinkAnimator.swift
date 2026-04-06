import Cocoa

final class DisplayLinkAnimator: @unchecked Sendable {
    private var displayLink: CVDisplayLink?
    private let duration: Double
    private let onUpdate: (CGFloat) -> Void
    private var startTime: Double = 0
    private var running = false

    init(duration: Double, onUpdate: @escaping (CGFloat) -> Void) {
        self.duration = duration
        self.onUpdate = onUpdate
    }

    func start() {
        startTime = CACurrentMediaTime()
        running = true

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let link = link else { return }

        let selfPtr = Unmanaged.passRetained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, userData -> CVReturn in
            guard let userData = userData else { return kCVReturnSuccess }
            let animator = Unmanaged<DisplayLinkAnimator>.fromOpaque(userData).takeUnretainedValue()
            animator.tick()
            return kCVReturnSuccess
        }, selfPtr)

        self.displayLink = link
        CVDisplayLinkStart(link)
    }

    func stop() {
        running = false
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
        displayLink = nil
    }

    private func tick() {
        let elapsed = CACurrentMediaTime() - startTime
        let progress = min(CGFloat(elapsed / duration), 1.0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.running else { return }
            self.onUpdate(progress)
            if progress >= 1.0 {
                self.stop()
            }
        }
    }

    deinit {
        stop()
    }
}
