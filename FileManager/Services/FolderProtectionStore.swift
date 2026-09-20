import Foundation
import Combine

final class FolderProtectionStore: ObservableObject {
    static let shared = FolderProtectionStore()

    @Published private(set) var hiddenPaths: Set<String>
    @Published private(set) var lockedPaths: Set<String>

    private let defaults = AppGroup.sharedDefaults
    private let hiddenKey = "FileManager.hiddenPaths"
    private let lockedKey = "FileManager.lockedPaths"

    private init() {
        hiddenPaths = Set(defaults.stringArray(forKey: hiddenKey) ?? [])
        lockedPaths = Set(defaults.stringArray(forKey: lockedKey) ?? [])
    }

    private func relativePath(for url: URL) -> String {
        let root = FileSystemService.shared.rootURL.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(root) {
            return String(path.dropFirst(root.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return path
    }

    func isHidden(_ url: URL) -> Bool {
        hiddenPaths.contains(relativePath(for: url))
    }

    func isLocked(_ url: URL) -> Bool {
        lockedPaths.contains(relativePath(for: url))
    }

    func setHidden(_ hidden: Bool, for url: URL) {
        let path = relativePath(for: url)
        if hidden {
            hiddenPaths.insert(path)
        } else {
            hiddenPaths.remove(path)
        }
        defaults.set(Array(hiddenPaths), forKey: hiddenKey)
    }

    func setLocked(_ locked: Bool, for url: URL) {
        let path = relativePath(for: url)
        if locked {
            lockedPaths.insert(path)
        } else {
            lockedPaths.remove(path)
        }
        defaults.set(Array(lockedPaths), forKey: lockedKey)
    }

    func hiddenFolderItems() -> [FileItem] {
        hiddenPaths.compactMap { path in
            let url = FileSystemService.shared.rootURL.appendingPathComponent(path, isDirectory: true)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return FileItem(url: url)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
