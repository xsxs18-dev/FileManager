import Foundation

struct FileItem: Identifiable, Hashable {
    let url: URL
    let isDirectory: Bool
    let fileSize: Int64?
    let modifiedDate: Date?

    var id: URL { url }

    var name: String { url.lastPathComponent }

    var fileExtension: String {
        url.pathExtension
    }

    init(url: URL) {
        self.url = url
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
        self.isDirectory = values?.isDirectory ?? false
        self.fileSize = values?.fileSize.map { Int64($0) }
        self.modifiedDate = values?.contentModificationDate
    }

    var formattedSize: String {
        guard let fileSize else { return "" }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        guard let modifiedDate else { return "" }
        return modifiedDate.formatted(date: .abbreviated, time: .shortened)
    }
}
