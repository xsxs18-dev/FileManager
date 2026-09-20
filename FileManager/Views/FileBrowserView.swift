import SwiftUI
import UIKit
import PDFKit

struct FileBrowserView: View {
    let directory: URL
    let title: String

    @State private var items: [FileItem] = []
    @State private var activeSheet: ActiveSheet?
    @State private var itemPendingRename: FileItem?
    @State private var itemPendingDelete: FileItem?
    @State private var errorMessage: String?
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<FileItem>()
    @State private var isScanning = false
    @State private var scannedImages: [UIImage] = []
    @State private var unlockedContext: UnlockedPDFContext?
    @ObservedObject private var protectionStore = FolderProtectionStore.shared

    private enum ActiveSheet: Identifiable {
        case newFolder
        case newFile
        case rename(FileItem)
        case zipCreate
        case extractPassword(FileItem)
        case imagesToPDF
        case textToPDF
        case scanNaming
        case encryptPDF(FileItem)
        case decryptPDF(FileItem)

        var id: String {
            switch self {
            case .newFolder: return "newFolder"
            case .newFile: return "newFile"
            case .rename(let item): return "rename-\(item.id)"
            case .zipCreate: return "zipCreate"
            case .extractPassword(let item): return "extractPassword-\(item.id)"
            case .imagesToPDF: return "imagesToPDF"
            case .textToPDF: return "textToPDF"
            case .scanNaming: return "scanNaming"
            case .encryptPDF(let item): return "encryptPDF-\(item.id)"
            case .decryptPDF(let item): return "decryptPDF-\(item.id)"
            }
        }
    }

    private struct UnlockedPDFContext: Identifiable {
        let id = UUID()
        let document: PDFDocument
        let item: FileItem
    }

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()

            if items.isEmpty {
                emptyState
            } else {
                List(selection: $selection) {
                    ForEach(items) { item in
                        row(for: item)
                            .tag(item)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(FVColor.background)
                .environment(\.editMode, $editMode)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        activeSheet = .newFolder
                    } label: {
                        Label("Neuer Ordner", systemImage: "folder.badge.plus")
                    }
                    Button {
                        activeSheet = .newFile
                    } label: {
                        Label("Neue Datei", systemImage: "doc.badge.plus")
                    }
                    Button {
                        createTextFile()
                    } label: {
                        Label("Neue Textdatei", systemImage: "doc.text")
                    }
                    Divider()
                    Button {
                        activeSheet = .imagesToPDF
                    } label: {
                        Label("PDF aus Bildern", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        activeSheet = .textToPDF
                    } label: {
                        Label("PDF aus Text", systemImage: "doc.richtext")
                    }
                    Button {
                        isScanning = true
                    } label: {
                        Label("Dokument scannen", systemImage: "camera.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(FVColor.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "Fertig" : "Auswählen") {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                    if editMode == .inactive { selection.removeAll() }
                }
                .foregroundStyle(FVColor.accent)
            }
            ToolbarItem(placement: .bottomBar) {
                if editMode == .active && !selection.isEmpty {
                    Button {
                        activeSheet = .zipCreate
                    } label: {
                        Label("Zip erstellen (\(selection.count))", systemImage: "doc.zipper")
                    }
                    .foregroundStyle(FVColor.accent)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newFolder:
                NameInputSheet(title: "Neuer Ordner", placeholder: "Ordnername") { name in
                    createFolder(named: name)
                }
            case .newFile:
                NameInputSheet(title: "Neue Datei", placeholder: "dateiname.ext") { name in
                    createFile(named: name)
                }
            case .rename(let item):
                NameInputSheet(
                    title: "Umbenennen",
                    placeholder: "Name",
                    initialValue: item.name,
                    confirmTitle: "Speichern"
                ) { name in
                    rename(item, to: name)
                }
            case .zipCreate:
                ZipCreateSheet(itemCount: selection.count) { name, password in
                    createZip(named: name, password: password)
                }
            case .extractPassword(let item):
                PasswordPromptSheet(
                    title: "Passwort erforderlich",
                    message: "Archiv „\(item.name)“ ist verschlüsselt."
                ) { password in
                    extract(item, password: password)
                }
            case .imagesToPDF:
                ImagesToPDFSheet { images, name in
                    createPDFFromImages(images, named: name)
                }
            case .textToPDF:
                TextToPDFSheet { text, name in
                    createPDFFromText(text, named: name)
                }
            case .scanNaming:
                NameInputSheet(
                    title: "PDF speichern",
                    placeholder: "Dateiname",
                    initialValue: "Scan",
                    confirmTitle: "Speichern"
                ) { name in
                    createPDFFromScan(named: name)
                }
            case .encryptPDF(let item):
                PasswordPromptSheet(
                    title: "PDF verschlüsseln",
                    message: "„\(item.name)“ mit Passwort schützen (AES, Owner- & User-Password).",
                    confirmTitle: "Verschlüsseln",
                    requiresConfirmation: true
                ) { password in
                    encryptPDF(item, password: password)
                }
            case .decryptPDF(let item):
                PasswordPromptSheet(
                    title: "Passwort eingeben",
                    message: "„\(item.name)“ ist passwortgeschützt.",
                    confirmTitle: "Entsperren"
                ) { password in
                    decryptPDF(item, password: password)
                }
            }
        }
        .fullScreenCover(isPresented: $isScanning) {
            DocumentScannerView(
                onFinish: { images in
                    isScanning = false
                    scannedImages = images
                    if !images.isEmpty { activeSheet = .scanNaming }
                },
                onCancel: {
                    isScanning = false
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $unlockedContext) { context in
            UnlockedPDFSheet(document: context.document, originalName: context.item.name) {
                saveUnlockedCopy(context)
            }
        }
        .alert("Fehler", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            "„\(itemPendingDelete?.name ?? "")“ löschen?",
            isPresented: .constant(itemPendingDelete != nil),
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) {
                if let item = itemPendingDelete { delete(item) }
                itemPendingDelete = nil
            }
            Button("Abbrechen", role: .cancel) { itemPendingDelete = nil }
        }
        .onAppear(perform: reload)
    }

    private var emptyState: some View {
        VStack(spacing: FVSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(FVColor.textSecondary)
            Text("Leer")
                .font(FVFont.body)
                .foregroundStyle(FVColor.textSecondary)
        }
    }

    @ViewBuilder
    private func row(for item: FileItem) -> some View {
        Group {
            if item.isDirectory {
                NavigationLink(value: item) {
                    rowLabel(for: item)
                }
            } else {
                rowLabel(for: item)
            }
        }
        .listRowBackground(FVColor.background)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            Button {
                activeSheet = .rename(item)
            } label: {
                Label("Umbenennen", systemImage: "pencil")
            }
            .tint(FVColor.accent)
        }
        .contextMenu {
            Button {
                activeSheet = .rename(item)
            } label: {
                Label("Umbenennen", systemImage: "pencil")
            }
            if item.isDirectory {
                Button {
                    protectionStore.setHidden(true, for: item.url)
                    reload()
                } label: {
                    Label("Verstecken", systemImage: "eye.slash")
                }
                Button {
                    protectionStore.setLocked(!protectionStore.isLocked(item.url), for: item.url)
                } label: {
                    if protectionStore.isLocked(item.url) {
                        Label("Face-ID-Sperre entfernen", systemImage: "lock.open")
                    } else {
                        Label("Mit Face ID sperren", systemImage: "lock")
                    }
                }
            }
            if !item.isDirectory && item.fileExtension.lowercased() == "zip" {
                Button {
                    startExtract(item)
                } label: {
                    Label("Entpacken", systemImage: "doc.zipper")
                }
            }
            if !item.isDirectory && item.fileExtension.lowercased() == "pdf" {
                if PDFService.shared.isEncrypted(at: item.url) {
                    Button {
                        activeSheet = .decryptPDF(item)
                    } label: {
                        Label("Entsperren", systemImage: "lock.open")
                    }
                } else {
                    Button {
                        activeSheet = .encryptPDF(item)
                    } label: {
                        Label("Verschlüsseln", systemImage: "lock")
                    }
                }
            }
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    private func rowLabel(for item: FileItem) -> some View {
        HStack(spacing: FVSpacing.md) {
            Image(systemName: item.isDirectory ? "folder.fill" : icon(for: item))
                .foregroundStyle(FVColor.accent)
                .font(.system(size: 20))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(FVFont.body)
                    .foregroundStyle(FVColor.textPrimary)
                if !item.isDirectory {
                    Text("\(item.formattedSize) · \(item.formattedDate)")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)
                }
            }
            Spacer()
            if item.isDirectory && protectionStore.isLocked(item.url) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(FVColor.textSecondary)
            }
        }
        .padding(.vertical, FVSpacing.xs)
    }

    private func icon(for item: FileItem) -> String {
        switch item.fileExtension.lowercased() {
        case "pdf": return "doc.richtext"
        case "zip": return "doc.zipper"
        case "txt": return "doc.plaintext"
        case "jpg", "jpeg", "png", "heic": return "photo"
        default: return "doc"
        }
    }

    private func reload() {
        do {
            items = try FileSystemService.shared.contents(of: directory).filter { item in
                !(item.isDirectory && protectionStore.isHidden(item.url))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createFolder(named name: String) {
        do {
            try FileSystemService.shared.createFolder(named: name, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createFile(named name: String) {
        do {
            try FileSystemService.shared.createFile(named: name, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createTextFile() {
        do {
            let base = "Neue Datei"
            var candidate = "\(base).txt"
            var counter = 1
            while FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
                counter += 1
                candidate = "\(base) \(counter).txt"
            }
            try FileSystemService.shared.createFile(named: candidate, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rename(_ item: FileItem, to newName: String) {
        do {
            try FileSystemService.shared.rename(item, to: newName)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ item: FileItem) {
        do {
            try FileSystemService.shared.delete(item)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createZip(named name: String, password: String?) {
        do {
            try ZipService.shared.createArchive(from: Array(selection), named: name, in: directory, password: password)
            selection.removeAll()
            editMode = .inactive
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startExtract(_ item: FileItem) {
        if ZipService.shared.isEncryptedArchive(at: item.url) {
            activeSheet = .extractPassword(item)
        } else {
            extract(item, password: nil)
        }
    }

    private func extract(_ item: FileItem, password: String?) {
        do {
            try ZipService.shared.extractArchive(at: item.url, to: directory, password: password)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createPDFFromImages(_ images: [UIImage], named name: String) {
        do {
            try PDFService.shared.createPDF(fromImages: images, named: name, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createPDFFromText(_ text: String, named name: String) {
        do {
            try PDFService.shared.createPDF(fromText: text, named: name, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createPDFFromScan(named name: String) {
        do {
            try PDFService.shared.createPDF(fromImages: scannedImages, named: name, in: directory)
            scannedImages = []
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func encryptPDF(_ item: FileItem, password: String) {
        do {
            try PDFService.shared.encrypt(at: item.url, password: password)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func decryptPDF(_ item: FileItem, password: String) {
        do {
            let document = try PDFService.shared.unlock(at: item.url, password: password)
            unlockedContext = UnlockedPDFContext(document: document, item: item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveUnlockedCopy(_ context: UnlockedPDFContext) {
        do {
            try PDFService.shared.saveUnlockedCopy(context.document, originalName: context.item.name, in: directory)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
