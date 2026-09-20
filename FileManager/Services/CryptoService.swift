import Foundation
import CryptoKit

enum CryptoServiceError: LocalizedError {
    case wrongPassword
    case encryptionFailed

    var errorDescription: String? {
        switch self {
        case .wrongPassword: return "Incorrect password."
        case .encryptionFailed: return "Encryption failed."
        }
    }
}

enum CryptoService {
    static let defaultIterations = 100_000

    static func deriveKey(password: String, salt: Data, iterations: Int = defaultIterations) -> SymmetricKey {
        var digest = SHA256.hash(data: Data(password.utf8) + salt)
        let rounds = max(1, iterations / 1000)
        for _ in 0..<rounds {
            digest = SHA256.hash(data: Data(digest) + salt)
        }
        return SymmetricKey(data: Data(digest))
    }

    static func randomSalt(length: Int = 16) -> Data {
        Data((0..<length).map { _ in UInt8.random(in: .min ... .max) })
    }

    static func encrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else { throw CryptoServiceError.encryptionFailed }
        return combined
    }

    static func decrypt(_ data: Data, key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw CryptoServiceError.wrongPassword
        }
    }
}
