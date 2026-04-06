import Foundation
import Combine

final class ProjectStore: ObservableObject, @unchecked Sendable {
    @Published var projects: [Project] = []
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("CCQuick")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("projects.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Project].self, from: data) else { return }
        projects = decoded
    }

    func save() {
        // Only persist pinned and opened projects, not auto-discovered ones
        let toSave = projects.filter { $0.isPinned || $0.lastOpened != nil }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(toSave) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func recordOpen(path: String) {
        if let idx = projects.firstIndex(where: { $0.path == path }) {
            projects[idx].lastOpened = Date()
        } else {
            projects.append(Project(path: path, lastOpened: Date()))
        }
        save()
    }

    func togglePin(path: String) {
        if let idx = projects.firstIndex(where: { $0.path == path }) {
            projects[idx].isPinned.toggle()
        } else {
            projects.append(Project(path: path, isPinned: true))
        }
        save()
    }

    func addDiscoveredRepos(_ paths: [String]) {
        let existing = Set(projects.map(\.path))
        for path in paths where !existing.contains(path) {
            projects.append(Project(path: path, isDiscovered: true))
        }
    }

    var pinnedProjects: [Project] {
        projects.filter(\.isPinned)
    }

    var recentProjects: [Project] {
        projects.filter { $0.lastOpened != nil && !$0.isPinned }
            .sorted { ($0.lastOpened ?? .distantPast) > ($1.lastOpened ?? .distantPast) }
    }

    func setIcon(path: String, icon: String?) {
        if let idx = projects.firstIndex(where: { $0.path == path }) {
            projects[idx].customIcon = icon
            save()
        }
    }

    var discoveredProjects: [Project] {
        projects.filter { $0.isDiscovered && !$0.isPinned && $0.lastOpened == nil }
    }
}
