import Foundation
import CryptoKit

enum FileEncryptionError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .invalidFile: return String(localized: "This is not a valid encrypted FileManager file.")
        }
    }
}

final class FileEncryptionService {
    static let shared = FileEncryptionService()
    private let saltLength = 16
    static let fileExtension = "fvenc"

    @discardableResult
    func encrypt(at url: URL, password: String) throws -> URL {
        let data = try Data(contentsOf: url)
        let salt = CryptoService.randomSalt(length: saltLength)
        let key = CryptoService.deriveKey(password: password, salt: salt)
        let encrypted = try CryptoService.encrypt(data, key: key)

        var payload = salt
        payload.append(encrypted)

        let destination = uniqueDestination(for: url.appendingPathExtension(Self.fileExtension))
        try payload.write(to: destination)
        try FileManager.default.removeItem(at: url)
        return destination
    }

    @discardableResult
    func decrypt(at url: URL, password: String) throws -> URL {
        guard url.pathExtension.lowercased() == Self.fileExtension else { throw FileEncryptionError.invalidFile }
        let payload = try Data(contentsOf: url)
        guard payload.count > saltLength else { throw FileEncryptionError.invalidFile }

        let salt = payload.prefix(saltLength)
        let ciphertext = payload.dropFirst(saltLength)
        let key = CryptoService.deriveKey(password: password, salt: Data(salt))
        let decrypted = try CryptoService.decrypt(Data(ciphertext), key: key)

        let destination = uniqueDestination(for: url.deletingPathExtension())
        try decrypted.write(to: destination)
        try FileManager.default.removeItem(at: url)
        return destination
    }

    private func uniqueDestination(for url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var counter = 1
        var candidate = url
        while FileManager.default.fileExists(atPath: candidate.path) {
            counter += 1
            candidate = ext.isEmpty
                ? directory.appendingPathComponent("\(base) \(counter)")
                : directory.appendingPathComponent("\(base) \(counter).\(ext)")
        }
        return candidate
    }
}
