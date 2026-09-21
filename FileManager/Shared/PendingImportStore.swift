import Foundation
import UIKit

enum PendingImportStore {
    struct Item {
        let name: String
        let data: Data
        let destinationPath: String
    }

    static let maxItemSize = 20_000_000

    private static let itemType = "com.xsxs18.filemanager.pending-import-item"

    static func queue(_ items: [Item]) {
        UIPasteboard.general.items = items.compactMap { item in
            guard let nameData = item.name.data(using: .utf8), nameData.count <= UInt32.max else { return nil }
            guard let destinationData = item.destinationPath.data(using: .utf8), destinationData.count <= UInt32.max else { return nil }
            var payload = encodedUInt32(UInt32(nameData.count))
            payload.append(nameData)
            payload.append(encodedUInt32(UInt32(destinationData.count)))
            payload.append(destinationData)
            payload.append(item.data)
            return [itemType: payload]
        }
    }

    static func takePending() -> [Item] {
        var remaining: [[String: Any]] = []
        var results: [Item] = []
        for entry in UIPasteboard.general.items {
            if let payload = entry[itemType] as? Data, let item = decode(payload) {
                results.append(item)
            } else {
                remaining.append(entry)
            }
        }
        if !results.isEmpty {
            UIPasteboard.general.items = remaining
        }
        return results
    }

    private static func encodedUInt32(_ value: UInt32) -> Data {
        Data([
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ])
    }

    private static func decodeUInt32(_ data: Data) -> UInt32 {
        data.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    private static func decode(_ payload: Data) -> Item? {
        var cursor = payload.startIndex
        guard let nameLength = readLength(payload, cursor: &cursor) else { return nil }
        guard let name = readString(payload, cursor: &cursor, length: nameLength) else { return nil }
        guard let destinationLength = readLength(payload, cursor: &cursor) else { return nil }
        guard let destinationPath = readString(payload, cursor: &cursor, length: destinationLength) else { return nil }
        let fileData = payload[cursor...]
        return Item(name: name, data: Data(fileData), destinationPath: destinationPath)
    }

    private static func readLength(_ payload: Data, cursor: inout Data.Index) -> Int? {
        guard cursor + 4 <= payload.endIndex else { return nil }
        let length = Int(decodeUInt32(payload[cursor..<cursor + 4]))
        cursor += 4
        return length
    }

    private static func readString(_ payload: Data, cursor: inout Data.Index, length: Int) -> String? {
        guard cursor + length <= payload.endIndex else { return nil }
        let string = String(data: payload[cursor..<cursor + length], encoding: .utf8)
        cursor += length
        return string
    }
}
