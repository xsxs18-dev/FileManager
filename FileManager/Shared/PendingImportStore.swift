import Foundation
import UIKit

enum PendingImportStore {
    struct Item {
        let name: String
        let data: Data
    }

    static let maxItemSize = 20_000_000

    private static let pasteboardName = UIPasteboard.Name("com.xsxs18.FileManager.pendingImport")
    private static let itemType = "com.xsxs18.filemanager.pending-import-item"

    static func queue(_ items: [Item]) {
        guard let pasteboard = UIPasteboard(name: pasteboardName, create: true) else { return }
        pasteboard.items = items.compactMap { item in
            guard let nameData = item.name.data(using: .utf8), nameData.count <= UInt32.max else { return nil }
            var payload = encodedUInt32(UInt32(nameData.count))
            payload.append(nameData)
            payload.append(item.data)
            return [itemType: payload]
        }
    }

    static func takePending() -> [Item] {
        guard let pasteboard = UIPasteboard(name: pasteboardName, create: false) else { return [] }
        let items = pasteboard.items.compactMap { entry -> Item? in
            guard let payload = entry[itemType] as? Data else { return nil }
            return decode(payload)
        }
        pasteboard.items = []
        return items
    }

    static var hasPending: Bool {
        guard let pasteboard = UIPasteboard(name: pasteboardName, create: false) else { return false }
        return !pasteboard.items.isEmpty
    }

    private static func encodedUInt32(_ value: UInt32) -> Data {
        Data([
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ])
    }

    private static func decode(_ payload: Data) -> Item? {
        guard payload.count > 4 else { return nil }
        let lengthBytes = payload.prefix(4)
        let length = lengthBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        let nameStart = payload.startIndex + 4
        let nameEnd = nameStart + Int(length)
        guard nameEnd <= payload.endIndex else { return nil }
        guard let name = String(data: payload[nameStart..<nameEnd], encoding: .utf8) else { return nil }
        let fileData = payload[nameEnd...]
        return Item(name: name, data: Data(fileData))
    }
}
