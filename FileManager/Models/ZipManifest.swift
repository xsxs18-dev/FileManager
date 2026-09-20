import Foundation

struct ZipManifest: Codable {
    static let fileName = "filemanager-manifest.json"

    let version: Int
    let saltBase64: String
    let kdfIterations: Int

    var salt: Data {
        Data(base64Encoded: saltBase64) ?? Data()
    }

    init(salt: Data, kdfIterations: Int) {
        self.version = 1
        self.saltBase64 = salt.base64EncodedString()
        self.kdfIterations = kdfIterations
    }
}
