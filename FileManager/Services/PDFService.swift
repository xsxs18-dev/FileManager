import PDFKit
import UIKit

enum PDFServiceError: LocalizedError {
    case renderingFailed
    case wrongPassword
    case notEncrypted

    var errorDescription: String? {
        switch self {
        case .renderingFailed: return "PDF konnte nicht erstellt werden."
        case .wrongPassword: return "Falsches Passwort."
        case .notEncrypted: return "Diese PDF ist nicht verschlüsselt."
        }
    }
}

final class PDFService {
    static let shared = PDFService()

    @discardableResult
    func createPDF(fromImages images: [UIImage], named name: String, in directory: URL) throws -> URL {
        let document = PDFDocument()
        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            document.insert(page, at: index)
        }
        guard document.pageCount > 0 else { throw PDFServiceError.renderingFailed }
        return try write(document, named: name, in: directory)
    }

    @discardableResult
    func createPDF(fromText text: String, named name: String, in directory: URL) throws -> URL {
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 48
        let textRect = pageBounds.insetBy(dx: margin, dy: margin)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        let attributed = NSAttributedString(string: text.isEmpty ? " " : text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let fullRange = CFRange(location: 0, length: attributed.length)

        let data = renderer.pdfData { context in
            var location = 0
            repeat {
                context.beginPage()
                let path = CGPath(rect: textRect, transform: nil)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: location, length: 0), path, nil)
                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: pageBounds.height)
                cgContext.scaleBy(x: 1, y: -1)
                CTFrameDraw(frame, cgContext)
                cgContext.restoreGState()
                let visibleRange = CTFrameGetVisibleStringRange(frame)
                if visibleRange.length == 0 { break }
                location += visibleRange.length
            } while location < fullRange.length
        }

        guard let document = PDFDocument(data: data) else { throw PDFServiceError.renderingFailed }
        return try write(document, named: name, in: directory)
    }

    private func write(_ document: PDFDocument, named name: String, in directory: URL) throws -> URL {
        let fileName = name.lowercased().hasSuffix(".pdf") ? name : "\(name).pdf"
        let destination = directory.appendingPathComponent(fileName)
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw FileSystemError.alreadyExists }
        guard document.write(to: destination) else { throw PDFServiceError.renderingFailed }
        return destination
    }

    func isEncrypted(at url: URL) -> Bool {
        guard let document = PDFDocument(url: url) else { return false }
        return document.isEncrypted && document.isLocked
    }

    func encrypt(at url: URL, password: String) throws {
        guard let document = PDFDocument(url: url) else { throw PDFServiceError.renderingFailed }
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        guard document.write(to: tempURL, withOptions: options) else { throw PDFServiceError.renderingFailed }
        try FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: tempURL, to: url)
    }

    func unlock(at url: URL, password: String) throws -> PDFDocument {
        guard let document = PDFDocument(url: url) else { throw PDFServiceError.renderingFailed }
        guard document.isEncrypted else { throw PDFServiceError.notEncrypted }
        guard document.unlock(withPassword: password) else { throw PDFServiceError.wrongPassword }
        return document
    }

    @discardableResult
    func saveUnlockedCopy(_ document: PDFDocument, originalName: String, in directory: URL) throws -> URL {
        let base = (originalName as NSString).deletingPathExtension
        var candidate = "\(base) (entsperrt).pdf"
        var counter = 1
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
            counter += 1
            candidate = "\(base) (entsperrt \(counter)).pdf"
        }
        let destination = directory.appendingPathComponent(candidate)
        guard document.write(to: destination) else { throw PDFServiceError.renderingFailed }
        return destination
    }
}
