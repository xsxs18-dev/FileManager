import SwiftUI

struct PendingImportQueueView: View {
    let items: [ShareItem]
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var isQueuing = false
    @State private var errorMessage: String?

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
                    Text("Open FileManager afterwards to finish bringing these into My Files.")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FVSpacing.lg)
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
            queued.append(PendingImportStore.Item(name: item.suggestedName, data: data))
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
