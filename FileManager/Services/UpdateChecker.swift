import Foundation

struct UpdateCheckResult {
    let isUpdateAvailable: Bool
    let currentVersion: String
    let latestVersion: String
    let releaseURL: URL
}

enum UpdateCheckError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return String(localized: "Could not check for updates.")
        }
    }
}

struct ChangelogEntry: Decodable, Identifiable {
    let tag_name: String
    let name: String?
    let body: String?
    let published_at: String?

    var id: String { tag_name }

    var displayVersion: String {
        guard let name, name.hasPrefix("FileManager ") else {
            return name ?? tag_name
        }
        return String(name.dropFirst("FileManager ".count))
    }

    var displayChanges: String {
        guard let body else { return "" }
        if let range = body.range(of: "### Changes\n") {
            return String(body[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayDate: String? {
        guard let published_at, let date = ISO8601DateFormatter().date(from: published_at) else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

final class UpdateChecker {
    static let shared = UpdateChecker()
    private let repo = "xsxs18-dev/FileManager"

    func checkForUpdate() async throws -> UpdateCheckResult {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateCheckError.invalidResponse
        }

        struct ReleaseResponse: Decodable {
            let tag_name: String
            let html_url: String
        }

        let release = try JSONDecoder().decode(ReleaseResponse.self, from: data)
        let latestBuildNumber = Self.buildNumber(from: release.tag_name)
        let currentVersionString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let currentBuildNumber = Int(currentVersionString) ?? 0
        let releaseURL = URL(string: release.html_url) ?? URL(string: "https://github.com/\(repo)/releases")!

        return UpdateCheckResult(
            isUpdateAvailable: latestBuildNumber > currentBuildNumber,
            currentVersion: currentVersionString,
            latestVersion: String(latestBuildNumber),
            releaseURL: releaseURL
        )
    }

    private static func buildNumber(from tag: String) -> Int {
        let digits = tag.split(separator: "-").last.map(String.init) ?? tag
        return Int(digits) ?? 0
    }

    func fetchChangelog() async throws -> [ChangelogEntry] {
        let url = URL(string: "https://api.github.com/repos/\(repo)/releases?per_page=20")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateCheckError.invalidResponse
        }
        return try JSONDecoder().decode([ChangelogEntry].self, from: data)
    }
}
