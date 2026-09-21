import Foundation
import UIKit

enum FolderIndexStore {
    private static let itemType = "com.xsxs18.filemanager.folder-index"

    static func publish(relativePaths: [String]) {
        guard let payload = try? JSONEncoder().encode(relativePaths) else { return }
        var items = UIPasteboard.general.items.filter { $0[itemType] == nil }
        items.append([itemType: payload])
        UIPasteboard.general.items = items
    }

    static func readFolders() -> [String]? {
        for entry in UIPasteboard.general.items {
            guard let payload = entry[itemType] as? Data else { continue }
            return try? JSONDecoder().decode([String].self, from: payload)
        }
        return nil
    }
}
