import Foundation
import ZIPFoundation
import CryptoKit

enum ZipServiceError: LocalizedError {
    case passwordRequired
    case nothingToArchive
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .passwordRequired: return String(localized: "This archive requires a password.")
        case .nothingToArchive: return String(localized: "No items selected.")
        case .underlying(let error): return error.localizedDescription
        }
    }
}

final class ZipService {
    static let shared = ZipService()
    private let fileManager = FileManager.default

    @discardableResult
    func createArchive(from items: [FileItem], named name: String, in directory: URL, password: String?) throws -> URL {
        guard !items.isEmpty else { throw ZipServiceError.nothingToArchive }
        let archiveName = name.hasSuffix(".zip") ? name : "\(name).zip"
        let destination = directory.appendingPathComponent(archiveName)
        guard !fileManager.fileExists(atPath: destination.path) else { throw FileSystemError.alreadyExists }

        let stagingDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: stagingDir) }

        if let password, !password.isEmpty {
            let salt = CryptoService.randomSalt()
            let key = CryptoService.deriveKey(password: password, salt: salt)
            for item in items {
                try encryptRecursively(item.url, into: stagingDir, key: key)
            }
            let manifest = ZipManifest(salt: salt, kdfIterations: CryptoService.defaultIterations)
            let manifestData = try JSONEncoder().encode(manifest)
            try manifestData.write(to: stagingDir.appendingPathComponent(ZipManifest.fileName))
        } else {
            for item in items {
                let target = stagingDir.appendingPathComponent(item.name)
                try fileManager.copyItem(at: item.url, to: target)
            }
        }

        do {
            try fileManager.zipItem(at: stagingDir, to: destination, shouldKeepParent: false)
        } catch {
            throw ZipServiceError.underlying(error)
        }
        return destination
    }

    @discardableResult
    func extractArchive(at archiveURL: URL, to directory: URL, password: String?) throws -> URL {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        do {
            try fileManager.unzipItem(at: archiveURL, to: tempDir)
        } catch {
            throw ZipServiceError.underlying(error)
        }

        let manifestURL = tempDir.appendingPathComponent(ZipManifest.fileName)
        let baseName = archiveURL.deletingPathExtension().lastPathComponent
        let destinationRoot = uniqueFolder(named: baseName, in: directory)
        try fileManager.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: manifestURL.path) {
            guard let password, !password.isEmpty else { throw ZipServiceError.passwordRequired }
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(ZipManifest.self, from: manifestData)
            let key = CryptoService.deriveKey(password: password, salt: manifest.salt, iterations: manifest.kdfIterations)
            try fileManager.removeItem(at: manifestURL)
            try decryptRecursively(tempDir, into: destinationRoot, key: key)
        } else {
            let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for url in contents {
                let target = destinationRoot.appendingPathComponent(url.lastPathComponent)
                try fileManager.moveItem(at: url, to: target)
            }
        }
        return destinationRoot
    }

    func isEncryptedArchive(at archiveURL: URL) -> Bool {
        guard let archive = try? Archive(url: archiveURL, accessMode: .read) else { return false }
        return archive[ZipManifest.fileName] != nil
    }

    private func uniqueFolder(named base: String, in directory: URL) -> URL {
        var candidate = directory.appendingPathComponent(base, isDirectory: true)
        var counter = 1
        while fileManager.fileExists(atPath: candidate.path) {
            counter += 1
            candidate = directory.appendingPathComponent("\(base) \(counter)", isDirectory: true)
        }
        return candidate
    }

    private func encryptRecursively(_ url: URL, into stagingDir: URL, key: SymmetricKey) throws {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        if isDirectory {
            let subDir = stagingDir.appendingPathComponent(url.lastPathComponent, isDirectory: true)
            try fileManager.createDirectory(at: subDir, withIntermediateDirectories: true)
            let children = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for child in children {
                try encryptRecursively(child, into: subDir, key: key)
            }
        } else {
            let data = try Data(contentsOf: url)
            let encrypted = try CryptoService.encrypt(data, key: key)
            let target = stagingDir.appendingPathComponent(url.lastPathComponent)
            try encrypted.write(to: target)
        }
    }

    private func decryptRecursively(_ sourceDir: URL, into destinationDir: URL, key: SymmetricKey) throws {
        let children = try fileManager.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: [.isDirectoryKey])
        for child in children {
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let target = destinationDir.appendingPathComponent(child.lastPathComponent)
            if isDirectory {
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
                try decryptRecursively(child, into: target, key: key)
            } else {
                let data = try Data(contentsOf: child)
                let decrypted = try CryptoService.decrypt(data, key: key)
                try decrypted.write(to: target)
            }
        }
    }
}
