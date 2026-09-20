import SwiftUI

struct FolderPickerView: View {
    let items: [ShareItem]
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            FolderPickerLevelView(directory: FileSystemService.shared.rootURL, title: "My Files", items: items, onComplete: onComplete)
                .navigationDestination(for: URL.self) { url in
                    FolderPickerLevelView(directory: url, title: url.lastPathComponent, items: items, onComplete: onComplete)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onCancel() }
                            .foregroundStyle(FVColor.accent)
                    }
                }
        }
        .preferredColorScheme(.dark)
        .tint(FVColor.accent)
    }
}

private struct FolderPickerLevelView: View {
    let directory: URL
    let title: String
    let items: [ShareItem]
    let onComplete: () -> Void

    @State private var folders: [FileItem] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showNewFolderSheet = false

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
                            NavigationLink(value: folder.url) {
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

                if items.isEmpty {
                    Text("No shareable file could be read from this item.")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.danger)
                        .padding(.horizontal, FVSpacing.md)
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.danger)
                        .padding(.horizontal, FVSpacing.md)
                }

                Button {
                    save()
                } label: {
                    Text(isSaving ? "Saving…" : "Save Here (\(items.count))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.fvPrimary)
                .padding(FVSpacing.md)
                .disabled(isSaving || items.isEmpty)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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

    private func reload() {
        let protectionStore = FolderProtectionStore.shared
        folders = (try? FileSystemService.shared.contents(of: directory))?
            .filter { $0.isDirectory && !protectionStore.isHidden($0.url) && !protectionStore.isLocked($0.url) } ?? []
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        for item in items {
            do {
                let data = try Data(contentsOf: item.temporaryURL)
                let name = uniqueName(for: item.suggestedName, in: directory)
                _ = try FileSystemService.shared.createFile(named: name, in: directory, contents: data)
                try? FileManager.default.removeItem(at: item.temporaryURL)
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
                return
            }
        }
        isSaving = false
        onComplete()
    }

    private func uniqueName(for suggestedName: String, in directory: URL) -> String {
        let base = (suggestedName as NSString).deletingPathExtension
        let ext = (suggestedName as NSString).pathExtension
        var candidate = suggestedName
        var counter = 1
        while FileManager.default.fileExists(atPath: directory.appendingPathComponent(candidate).path) {
            counter += 1
            candidate = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
        }
        return candidate
    }
}
