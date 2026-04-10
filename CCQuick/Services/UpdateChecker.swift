import Foundation
import Cocoa

final class UpdateChecker: @unchecked Sendable {
    static let shared = UpdateChecker()
    private let repo = "hyojoongit/ccquick"
    private let currentVersion = "1.0.0"

    private init() {}

    func checkForUpdates(silent: Bool = true) {
        let urlString = "https://api.github.com/repos/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return
            }

            let latestVersion = tagName.replacingOccurrences(of: "v", with: "")

            if self.isNewer(latestVersion, than: self.currentVersion) {
                let htmlURL = json["html_url"] as? String ?? "https://github.com/\(self.repo)/releases/latest"
                DispatchQueue.main.async {
                    self.showUpdateAlert(newVersion: latestVersion, url: htmlURL)
                }
            } else if !silent {
                DispatchQueue.main.async {
                    self.showUpToDateAlert()
                }
            }
        }.resume()
    }

    private func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }

    private func showUpdateAlert(newVersion: String, url: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "CCQuick v\(newVersion) is available. You're currently on v\(currentVersion)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let downloadURL = URL(string: url) {
                NSWorkspace.shared.open(downloadURL)
            }
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "CCQuick v\(currentVersion) is the latest version."
        alert.alertStyle = .informational
        alert.runModal()
    }
}
