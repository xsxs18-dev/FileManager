import Foundation

enum FileSystemError: LocalizedError {
    case alreadyExists
    case invalidName
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .alreadyExists:
            return String(localized: "An item with this name already exists.")
        case .invalidName:
            return String(localized: "Invalid name.")
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

final class FileSystemService {
    static let shared = FileSystemService()

    private let fileManager = FileManager.default

    var rootURL: URL {
        let url = AppGroup.containerURL.appendingPathComponent("Vault", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func contents(of directory: URL) throws -> [FileItem] {
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        let items = urls.map { FileItem(url: $0) }
        return items.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    func allImageFiles(in directory: URL) -> [FileItem] {
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff"]
        let protectionStore = FolderProtectionStore.shared
        var results: [FileItem] = []
        guard let items = try? contents(of: directory) else { return results }
        for item in items {
            if item.isDirectory {
                guard !protectionStore.isHidden(item.url), !protectionStore.isLocked(item.url) else { continue }
                results.append(contentsOf: allImageFiles(in: item.url))
            } else if imageExtensions.contains(item.fileExtension.lowercased()) {
                results.append(item)
            }
        }
        return results
    }

    @discardableResult
    func createFolder(named name: String, in directory: URL) throws -> URL {
        let sanitized = sanitize(name)
        guard !sanitized.isEmpty else { throw FileSystemError.invalidName }
        let url = directory.appendingPathComponent(sanitized, isDirectory: true)
        guard !fileManager.fileExists(atPath: url.path) else { throw FileSystemError.alreadyExists }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
            return url
        } catch {
            throw FileSystemError.underlying(error)
        }
    }

    @discardableResult
    func createFile(named name: String, in directory: URL, contents: Data = Data()) throws -> URL {
        let sanitized = sanitize(name)
        guard !sanitized.isEmpty else { throw FileSystemError.invalidName }
        let url = directory.appendingPathComponent(sanitized, isDirectory: false)
        guard !fileManager.fileExists(atPath: url.path) else { throw FileSystemError.alreadyExists }
        guard fileManager.createFile(atPath: url.path, contents: contents) else {
            throw FileSystemError.underlying(NSError(domain: "FileSystemService", code: -1))
        }
        return url
    }

    @discardableResult
    func rename(_ item: FileItem, to newName: String) throws -> URL {
        let sanitized = sanitize(newName)
        guard !sanitized.isEmpty else { throw FileSystemError.invalidName }
        let destination = item.url.deletingLastPathComponent().appendingPathComponent(sanitized, isDirectory: item.isDirectory)
        guard !fileManager.fileExists(atPath: destination.path) else { throw FileSystemError.alreadyExists }
        do {
            try fileManager.moveItem(at: item.url, to: destination)
            return destination
        } catch {
            throw FileSystemError.underlying(error)
        }
    }

    func move(_ item: FileItem, to directory: URL) throws {
        let destination = directory.appendingPathComponent(item.name, isDirectory: item.isDirectory)
        guard !fileManager.fileExists(atPath: destination.path) else { throw FileSystemError.alreadyExists }
        do {
            try fileManager.moveItem(at: item.url, to: destination)
        } catch {
            throw FileSystemError.underlying(error)
        }
    }

    func delete(_ item: FileItem) throws {
        do {
            try fileManager.removeItem(at: item.url)
        } catch {
            throw FileSystemError.underlying(error)
        }
    }

    private func sanitize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let forbidden = CharacterSet(charactersIn: "/\\:")
        return trimmed.components(separatedBy: forbidden).joined()
    }
}
