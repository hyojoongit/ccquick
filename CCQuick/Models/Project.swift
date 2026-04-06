import Foundation

struct Project: Codable, Identifiable, Hashable {
    var id: String { path }
    let path: String
    let name: String
    var lastOpened: Date?
    var isPinned: Bool
    var isDiscovered: Bool
    var customIcon: String?  // SF Symbol name, nil = default

    init(path: String, lastOpened: Date? = nil, isPinned: Bool = false, isDiscovered: Bool = false, customIcon: String? = nil) {
        self.path = path
        self.name = URL(fileURLWithPath: path).lastPathComponent
        self.lastOpened = lastOpened
        self.isPinned = isPinned
        self.isDiscovered = isDiscovered
        self.customIcon = customIcon
    }

    var isGitRepo: Bool {
        FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git"))
    }

    var displayIcon: String {
        if let custom = customIcon { return custom }
        return "folder.fill"
    }
}
