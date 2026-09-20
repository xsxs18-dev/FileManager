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
    @State private var previewItem: FileItem?
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
            } else if editMode == .active {
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
            } else {
                List {
                    ForEach(items) { item in
                        row(for: item)
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
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                    Button {
                        activeSheet = .newFile
                    } label: {
                        Label("New File", systemImage: "doc.badge.plus")
                    }
                    Button {
                        createTextFile()
                    } label: {
                        Label("New Text File", systemImage: "doc.text")
                    }
                    Divider()
                    Button {
                        activeSheet = .imagesToPDF
                    } label: {
                        Label("PDF from Images", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        activeSheet = .textToPDF
                    } label: {
                        Label("PDF from Text", systemImage: "doc.richtext")
                    }
                    Button {
                        isScanning = true
                    } label: {
                        Label("Scan Document", systemImage: "camera.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(FVColor.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(editMode == .active ? "Done" : "Select") {
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
                        Label("Create Zip (\(selection.count))", systemImage: "doc.zipper")
                    }
                    .foregroundStyle(FVColor.accent)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newFolder:
                NameInputSheet(title: "New Folder", placeholder: "Folder name") { name in
                    createFolder(named: name)
                }
            case .newFile:
                NameInputSheet(title: "New File", placeholder: "filename.ext") { name in
                    createFile(named: name)
                }
            case .rename(let item):
                NameInputSheet(
                    title: "Rename",
                    placeholder: "Name",
                    initialValue: item.name,
                    confirmTitle: "Save"
                ) { name in
                    rename(item, to: name)
                }
            case .zipCreate:
                ZipCreateSheet(itemCount: selection.count) { name, password in
                    createZip(named: name, password: password)
                }
            case .extractPassword(let item):
                PasswordPromptSheet(
                    title: "Password Required",
                    message: "Archive \"\(item.name)\" is encrypted."
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
                    title: "Save PDF",
                    placeholder: "File name",
                    initialValue: "Scan",
                    confirmTitle: "Save"
                ) { name in
                    createPDFFromScan(named: name)
                }
            case .encryptPDF(let item):
                PasswordPromptSheet(
                    title: "Encrypt PDF",
                    message: "Protect \"\(item.name)\" with a password (AES, owner & user password).",
                    confirmTitle: "Encrypt",
                    requiresConfirmation: true
                ) { password in
                    encryptPDF(item, password: password)
                }
            case .decryptPDF(let item):
                PasswordPromptSheet(
                    title: "Enter Password",
                    message: "\"\(item.name)\" is password protected.",
                    confirmTitle: "Unlock"
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
        .fullScreenCover(item: $previewItem) { item in
            FilePreviewSheet(item: item) {
                previewItem = nil
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            "Delete \"\(itemPendingDelete?.name ?? "")\"?",
            isPresented: .constant(itemPendingDelete != nil),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = itemPendingDelete { delete(item) }
                itemPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { itemPendingDelete = nil }
        }
        .onAppear(perform: reload)
    }

    private var emptyState: some View {
        VStack(spacing: FVSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(FVColor.textSecondary)
            Text("Empty")
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
                Button {
                    openFile(item)
                } label: {
                    rowLabel(for: item)
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(FVColor.background)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                activeSheet = .rename(item)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(FVColor.accent)
        }
        .contextMenu {
            Button {
                activeSheet = .rename(item)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            if item.isDirectory {
                Button {
                    protectionStore.setHidden(true, for: item.url)
                    reload()
                } label: {
                    Label("Hide", systemImage: "eye.slash")
                }
                Button {
                    protectionStore.setLocked(!protectionStore.isLocked(item.url), for: item.url)
                } label: {
                    if protectionStore.isLocked(item.url) {
                        Label("Remove Face ID Lock", systemImage: "lock.open")
                    } else {
                        Label("Lock with Face ID", systemImage: "lock")
                    }
                }
            }
            if !item.isDirectory && item.fileExtension.lowercased() == "zip" {
                Button {
                    startExtract(item)
                } label: {
                    Label("Extract", systemImage: "doc.zipper")
                }
            }
            if !item.isDirectory && item.fileExtension.lowercased() == "pdf" {
                if PDFService.shared.isEncrypted(at: item.url) {
                    Button {
                        activeSheet = .decryptPDF(item)
                    } label: {
                        Label("Unlock", systemImage: "lock.open")
                    }
                } else {
                    Button {
                        activeSheet = .encryptPDF(item)
                    } label: {
                        Label("Encrypt", systemImage: "lock")
                    }
                }
            }
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("Delete", systemImage: "trash")
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
            let base = "New File"
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

    private func openFile(_ item: FileItem) {
        if item.fileExtension.lowercased() == "pdf" && PDFService.shared.isEncrypted(at: item.url) {
            activeSheet = .decryptPDF(item)
        } else {
            previewItem = item
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
