import SwiftUI

struct PendingImportQueueView: View {
    let items: [ShareItem]
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var isQueuing = false
    @State private var errorMessage: String?
    @State private var availableFolders: [String] = []
    @State private var selectedFolder = ""

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(spacing: FVSpacing.lg) {
                    Spacer()
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(FVColor.accent)
                    Text("Send \(items.count) file(s) to FileManager")
                        .font(FVFont.headline)
                        .foregroundStyle(FVColor.textPrimary)
                    if !availableFolders.isEmpty {
                        Menu {
                            Button("My Files") { selectedFolder = "" }
                            ForEach(availableFolders, id: \.self) { folder in
                                Button(folder) { selectedFolder = folder }
                            }
                        } label: {
                            HStack {
                                Text("Destination")
                                    .foregroundStyle(FVColor.textPrimary)
                                Spacer()
                                Text(selectedFolder.isEmpty ? "My Files" : selectedFolder)
                                    .foregroundStyle(FVColor.textSecondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(FVColor.textSecondary)
                            }
                            .padding()
                            .background(FVColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, FVSpacing.lg)
                        Text("This list is from the last time you had FileManager open. Open FileManager first if a folder you expect is missing.")
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FVSpacing.lg)
                    } else {
                        Text("Open FileManager afterwards to finish bringing these into My Files. This briefly uses the system clipboard to hand the files over, so whatever you last copied will be replaced.")
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FVSpacing.lg)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FVSpacing.lg)
                    }
                    Spacer()
                    Button {
                        queue()
                    } label: {
                        Text(isQueuing ? "Sending…" : "Send")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.fvPrimary)
                    .padding(.horizontal, FVSpacing.lg)
                    .padding(.bottom, FVSpacing.lg)
                    .disabled(isQueuing || items.isEmpty)
                }
            }
            .navigationTitle("FileManager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FVColor.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(FVColor.accent)
        .onAppear {
            availableFolders = FolderIndexStore.readFolders() ?? []
        }
    }

    private func queue() {
        isQueuing = true
        errorMessage = nil

        var queued: [PendingImportStore.Item] = []
        for item in items {
            guard let data = try? Data(contentsOf: item.temporaryURL) else { continue }
            guard data.count <= PendingImportStore.maxItemSize else {
                let megabytes = PendingImportStore.maxItemSize / 1_000_000
                errorMessage = String(localized: "\"\(item.suggestedName)\" is too large to send this way (over \(megabytes) MB).")
                isQueuing = false
                return
            }
            queued.append(PendingImportStore.Item(name: item.suggestedName, data: data, destinationPath: selectedFolder))
        }

        guard !queued.isEmpty else {
            errorMessage = String(localized: "No shareable file could be read from this item.")
            isQueuing = false
            return
        }

        PendingImportStore.queue(queued)
        for item in items {
            try? FileManager.default.removeItem(at: item.temporaryURL)
        }
        isQueuing = false
        onComplete()
    }
}
