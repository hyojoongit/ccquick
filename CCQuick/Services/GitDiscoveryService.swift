import Foundation

final class GitDiscoveryService: @unchecked Sendable {
    private let scanRoots: [String]
    private let maxDepth: Int
    private let skipDirs: Set<String> = [
        "node_modules", ".build", "Pods", "vendor", "DerivedData",
        ".Trash", "Library", ".cargo", ".rustup", ".npm", ".cache"
    ]

    init(scanRoots: [String]? = nil, maxDepth: Int? = nil) {
        self.scanRoots = scanRoots ?? Preferences.shared.scanDirectories
        self.maxDepth = maxDepth ?? Preferences.shared.scanDepth
    }

    func discover(completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var repos: [String] = []
            let fm = FileManager.default

            for root in self.scanRoots {
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: root, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }
                self.scanDirectory(root, depth: 0, maxDepth: self.maxDepth, fm: fm, repos: &repos)
            }

            let unique = Array(Set(repos)).sorted()
            DispatchQueue.main.async {
                completion(unique)
            }
        }
    }

    private func scanDirectory(_ path: String, depth: Int, maxDepth: Int, fm: FileManager, repos: inout [String]) {
        guard depth <= maxDepth else { return }

        let gitPath = (path as NSString).appendingPathComponent(".git")
        if fm.fileExists(atPath: gitPath) {
            repos.append(path)
            return // Don't recurse into git repos (skip submodules for speed)
        }

        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }

        for item in contents {
            // Skip hidden dirs (except we already checked .git) and known heavy dirs
            if item.hasPrefix(".") || skipDirs.contains(item) { continue }

            let fullPath = (path as NSString).appendingPathComponent(item)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                scanDirectory(fullPath, depth: depth + 1, maxDepth: maxDepth, fm: fm, repos: &repos)
            }
        }
    }
}
