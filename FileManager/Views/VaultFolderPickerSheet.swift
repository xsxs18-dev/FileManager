import SwiftUI

struct VaultFolderPickerSheet: View {
    enum Mode {
        case move
        case copy
    }

    let mode: Mode
    let items: [FileItem]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VaultFolderPickerLevelView(
                mode: mode,
                items: items,
                directory: FileSystemService.shared.rootURL,
                title: String(localized: "My Files")
            ) {
                onComplete()
                dismiss()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
    }
}

private struct VaultFolderPickerLevelView: View {
    let mode: VaultFolderPickerSheet.Mode
    let items: [FileItem]
    let directory: URL
    let title: String
    let onComplete: () -> Void

    @State private var folders: [FileItem] = []
    @State private var errorMessage: String?
    @State private var showNewFolderSheet = false
    @ObservedObject private var protectionStore = FolderProtectionStore.shared

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if folders.isEmpty {
                    Spacer()
                    Text("No subfolders")
                        .foregroundStyle(FVColor.textSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(folders) { folder in
                            NavigationLink {
                                VaultFolderPickerLevelView(
                                    mode: mode,
                                    items: items,
                                    directory: folder.url,
                                    title: folder.name,
                                    onComplete: onComplete
                                )
                            } label: {
                                HStack(spacing: FVSpacing.md) {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(FVColor.accent)
                                    Text(folder.name)
                                        .foregroundStyle(FVColor.textPrimary)
                                }
                            }
                            .listRowBackground(FVColor.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.danger)
                        .padding(.horizontal, FVSpacing.md)
                }

                Button {
                    perform()
                } label: {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.fvPrimary)
                .padding(FVSpacing.md)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewFolderSheet = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NameInputSheet(title: "New Folder", placeholder: "Folder name") { name in
                _ = try? FileSystemService.shared.createFolder(named: name, in: directory)
                reload()
            }
        }
        .onAppear(perform: reload)
    }

    private var actionTitle: LocalizedStringKey {
        switch mode {
        case .move: return "Move Here"
        case .copy: return "Copy Here"
        }
    }

    private func reload() {
        folders = (try? FileSystemService.shared.contents(of: directory))?
            .filter { $0.isDirectory && !protectionStore.isHidden($0.url) && !protectionStore.isLocked($0.url) } ?? []
    }

    private func perform() {
        errorMessage = nil
        for item in items {
            do {
                switch mode {
                case .move:
                    try FileSystemService.shared.move(item, to: directory)
                case .copy:
                    try FileSystemService.shared.copy(item, to: directory)
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        onComplete()
    }
}
