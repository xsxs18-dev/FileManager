import SwiftUI

struct HiddenAreaView: View {
    @ObservedObject private var protectionStore = FolderProtectionStore.shared
    @State private var items: [FileItem] = []
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<FileItem>()
    @State private var activeSheet: ActiveSheet?
    @State private var itemPendingDelete: FileItem?
    @State private var isConfirmingBulkDelete = false
    @State private var errorMessage: String?

    private enum ActiveSheet: Identifiable {
        case rename(FileItem)
        case move(FileItem)
        case copy(FileItem)
        case moveSelection
        case copySelection

        var id: String {
            switch self {
            case .rename(let item): return "rename-\(item.id)"
            case .move(let item): return "move-\(item.id)"
            case .copy(let item): return "copy-\(item.id)"
            case .moveSelection: return "moveSelection"
            case .copySelection: return "copySelection"
            }
        }
    }

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            if items.isEmpty {
                VStack(spacing: FVSpacing.sm) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(FVColor.textSecondary)
                    Text("No hidden folders")
                        .font(FVFont.body)
                        .foregroundStyle(FVColor.textSecondary)
                }
            } else if editMode == .active {
                List(selection: $selection) {
                    ForEach(items) { item in
                        row(for: item)
                            .tag(item)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
            } else {
                List {
                    ForEach(items) { item in
                        row(for: item)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, $editMode)
            }
        }
        .navigationTitle("Hidden Area")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .toolbar {
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
                        unhideSelection()
                    } label: {
                        Label("Unhide", systemImage: "eye")
                    }
                    .foregroundStyle(FVColor.accent)
                    Spacer()
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
            case .rename(let item):
                NameInputSheet(
                    title: "Rename",
                    placeholder: "Name",
                    initialValue: item.name,
                    confirmTitle: "Save"
                ) { name in
                    rename(item, to: name)
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
    }

    @ViewBuilder
    private func row(for item: FileItem) -> some View {
        NavigationLink {
            FolderDestinationView(item: item)
        } label: {
            HStack(spacing: FVSpacing.md) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(FVColor.accent)
                    .frame(width: 28)
                Text(item.name)
                    .foregroundStyle(FVColor.textPrimary)
                Spacer()
                if protectionStore.isLocked(item.url) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(FVColor.textSecondary)
                }
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
                protectionStore.setHidden(false, for: item.url)
                reload()
            } label: {
                Label("Unhide", systemImage: "eye")
            }
            .tint(FVColor.accent)
        }
        .contextMenu {
            Button {
                activeSheet = .rename(item)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button {
                protectionStore.setHidden(false, for: item.url)
                reload()
            } label: {
                Label("Unhide", systemImage: "eye")
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
            Button(role: .destructive) {
                itemPendingDelete = item
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func reload() {
        items = protectionStore.hiddenFolderItems()
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

    private func unhideSelection() {
        for item in selection {
            protectionStore.setHidden(false, for: item.url)
        }
        selection.removeAll()
        editMode = .inactive
        reload()
    }
}
