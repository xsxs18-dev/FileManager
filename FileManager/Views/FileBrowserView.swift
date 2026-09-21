import SwiftUI
import UIKit
import PDFKit
import PhotosUI
import UniformTypeIdentifiers

struct FileBrowserView: View {
    let directory: URL
    let title: String

    @State private var items: [FileItem] = []
    @State private var activeSheet: ActiveSheet?
    @State private var itemPendingDelete: FileItem?
    @State private var isConfirmingBulkDelete = false
    @State private var errorMessage: String?
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<FileItem>()
    @State private var activeCover: ActiveCover?
    @State private var scannedImages: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
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
        case newTextFile
        case editText(FileItem)
        case encryptFile(FileItem)
        case decryptFile(FileItem)
        case move(FileItem)
        case copy(FileItem)
        case moveSelection
        case copySelection

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
            case .newTextFile: return "newTextFile"
            case .editText(let item): return "editText-\(item.id)"
            case .encryptFile(let item): return "encryptFile-\(item.id)"
            case .decryptFile(let item): return "decryptFile-\(item.id)"
            case .move(let item): return "move-\(item.id)"
            case .copy(let item): return "copy-\(item.id)"
            case .moveSelection: return "moveSelection"
            case .copySelection: return "copySelection"
            }
        }
    }

    private struct UnlockedPDFContext: Identifiable {
        let id = UUID()
        let document: PDFDocument
        let item: FileItem
    }

    private enum ActiveCover: Identifiable {
        case scanner
        case importPicker
        case unlockedPDF(UnlockedPDFContext)
        case preview(FileItem)

        var id: String {
            switch self {
            case .scanner: return "scanner"
            case .importPicker: return "importPicker"
            case .unlockedPDF(let context): return "unlockedPDF-\(context.id)"
            case .preview(let item): return "preview-\(item.id)"
            }
        }
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
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
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
                        activeSheet = .newTextFile
                    } label: {
                        Label("New Text File", systemImage: "doc.text")
                    }
                    Button {
                        activeCover = .importPicker
                    } label: {
                        Label("Import File", systemImage: "square.and.arrow.down")
                    }
                    PhotosPicker(selection: $photoPickerItems, matching: .any(of: [.images, .videos])) {
                        Label("Import Photo", systemImage: "photo.badge.plus")
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
                        activeCover = .scanner
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
            ToolbarItemGroup(placement: .bottomBar) {
                if editMode == .active && !selection.isEmpty {
                    Button {
                        activeSheet = .moveSelection
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .foregroundStyle(FVColor.accent)
                    Spacer()
                    Button {
                        activeSheet = .copySelection
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .foregroundStyle(FVColor.accent)
                    Spacer()
                    let shareURLs = selection.filter { !$0.isDirectory }.map(\.url)
                    if !shareURLs.isEmpty {
                        ShareLink(items: shareURLs) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .foregroundStyle(FVColor.accent)
                        Spacer()
                    }
                    Button {
                        activeSheet = .zipCreate
                    } label: {
                        Label("Create Zip (\(selection.count))", systemImage: "doc.zipper")
                    }
                    .foregroundStyle(FVColor.accent)
                    Spacer()
                    Button(role: .destructive) {
                        isConfirmingBulkDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .foregroundStyle(FVColor.danger)
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
            case .newTextFile:
                NewTextFileSheet { name, content in
                    createTextFile(named: name, content: content)
                }
            case .editText(let item):
                TextFileEditorView(
                    title: item.name,
                    initialContent: (try? String(contentsOf: item.url, encoding: .utf8)) ?? ""
                ) { content in
                    saveTextFile(item, content: content)
                }
            case .encryptFile(let item):
                PasswordPromptSheet(
                    title: "Encrypt File",
                    message: "Protect \"\(item.name)\" with a password (AES-256).",
                    confirmTitle: "Encrypt",
                    requiresConfirmation: true
                ) { password in
                    encryptFile(item, password: password)
                }
            case .decryptFile(let item):
                PasswordPromptSheet(
                    title: "Enter Password",
                    message: "\"\(item.name)\" is encrypted.",
                    confirmTitle: "Decrypt"
                ) { password in
                    decryptFile(item, password: password)
                }
            case .move(let item):
                VaultFolderPickerSheet(mode: .move, items: [item]) {
                    reload()
                }
            case .copy(let item):
                VaultFolderPickerSheet(mode: .copy, items: [item]) {
                    reload()
                }
            case .moveSelection:
                VaultFolderPickerSheet(mode: .move, items: Array(selection)) {
                    selection.removeAll()
                    editMode = .inactive
                    reload()
                }
            case .copySelection:
                VaultFolderPickerSheet(mode: .copy, items: Array(selection)) {
                    selection.removeAll()
                    editMode = .inactive
                    reload()
                }
            }
        }
        .fullScreenCover(item: $activeCover) { cover in
            switch cover {
            case .scanner:
                DocumentScannerView(
                    onFinish: { images in
                        activeCover = nil
                        scannedImages = images
                        if !images.isEmpty { activeSheet = .scanNaming }
                    },
                    onCancel: {
                        activeCover = nil
                    }
                )
                .ignoresSafeArea()
            case .importPicker:
                DocumentPickerView(
                    onPick: { urls in
                        activeCover = nil
                        importFiles(urls)
                    },
                    onCancel: {
                        activeCover = nil
                    }
                )
                .ignoresSafeArea()
            case .unlockedPDF(let context):
                UnlockedPDFSheet(document: context.document, originalName: context.item.name) {
                    saveUnlockedCopy(context)
                }
            case .preview(let item):
                FilePreviewSheet(item: item) {
                    activeCover = nil
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { isPresented in if !isPresented { errorMessage = nil } }
        ), presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            "Delete \"\(itemPendingDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { itemPendingDelete != nil },
                set: { isPresented in if !isPresented { itemPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = itemPendingDelete { delete(item) }
                itemPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { itemPendingDelete = nil }
        }
        .confirmationDialog(
            "Delete \(selection.count) item(s)?",
            isPresented: $isConfirmingBulkDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelection()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: reload)
        .onChange(of: photoPickerItems) { _, newItems in
            importPhotos(newItems)
        }
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
                NavigationLink {
                    FolderDestinationView(item: item)
                } label: {
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
            if !item.isDirectory {
                Button {
                    activeSheet = .move(item)
                } label: {
                    Label("Move", systemImage: "folder")
                }
                Button {
                    activeSheet = .copy(item)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                ShareLink(item: item.url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
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
            if !item.isDirectory {
                let ext = item.fileExtension.lowercased()
                if ext == FileEncryptionService.fileExtension {
                    Button {
                        activeSheet = .decryptFile(item)
                    } label: {
                        Label("Decrypt", systemImage: "lock.open")
                    }
                } else if ext != "pdf" && ext != "zip" {
                    Button {
                        activeSheet = .encryptFile(item)
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
        case "zip", "rar", "7z": return "doc.zipper"
        case "txt", "rtf", "md": return "doc.plaintext"
        case "jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff", "webp": return "photo"
        case "mp3", "wav", "aac", "m4a", "flac", "aiff": return "music.note"
        case "mp4", "mov", "m4v", "avi", "mkv": return "film"
        case "doc", "docx", "pages": return "doc.text"
        case "xls", "xlsx", "numbers", "csv": return "tablecells"
        case "ppt", "pptx", "key": return "rectangle.on.rectangle"
        case FileEncryptionService.fileExtension: return "lock.doc"
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

    private func importFiles(_ urls: [URL]) {
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                let name = FileSystemService.shared.uniqueName(for: url.lastPathComponent, in: directory)
                try FileSystemService.shared.createFile(named: name, in: directory, contents: data)
                try? FileManager.default.removeItem(at: url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        reload()
    }

    private func importPhotos(_ pickerItems: [PhotosPickerItem]) {
        guard !pickerItems.isEmpty else { return }
        Task {
            for pickerItem in pickerItems {
                guard let data = try? await pickerItem.loadTransferable(type: Data.self) else { continue }
                let contentType = pickerItem.supportedContentTypes.first
                let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
                let baseName = contentType?.conforms(to: .movie) == true ? "Video" : "Photo"
                let name = FileSystemService.shared.uniqueName(for: "\(baseName).\(fileExtension)", in: directory)
                try? FileSystemService.shared.createFile(named: name, in: directory, contents: data)
            }
            await MainActor.run {
                photoPickerItems = []
                reload()
            }
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

    private func createTextFile(named name: String, content: String) {
        do {
            let data = content.data(using: .utf8) ?? Data()
            try FileSystemService.shared.createFile(named: name, in: directory, contents: data)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTextFile(_ item: FileItem, content: String) {
        do {
            try (content.data(using: .utf8) ?? Data()).write(to: item.url)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func encryptFile(_ item: FileItem, password: String) {
        do {
            try FileEncryptionService.shared.encrypt(at: item.url, password: password)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func decryptFile(_ item: FileItem, password: String) {
        do {
            try FileEncryptionService.shared.decrypt(at: item.url, password: password)
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

    private func deleteSelection() {
        for item in selection {
            do {
                try FileSystemService.shared.delete(item)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        selection.removeAll()
        editMode = .inactive
        reload()
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
            activeCover = .unlockedPDF(UnlockedPDFContext(document: document, item: item))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openFile(_ item: FileItem) {
        let ext = item.fileExtension.lowercased()
        if ext == "pdf" && PDFService.shared.isEncrypted(at: item.url) {
            activeSheet = .decryptPDF(item)
        } else if ext == FileEncryptionService.fileExtension {
            activeSheet = .decryptFile(item)
        } else if ext == "txt" {
            activeSheet = .editText(item)
        } else {
            activeCover = .preview(item)
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
