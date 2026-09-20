import SwiftUI
import PhotosUI

struct ImagesToPDFSheet: View {
    let onConfirm: (_ images: [UIImage], _ name: String) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var name = "Document"
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: FVSpacing.md) {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Label(images.isEmpty ? "Select Images" : "\(images.count) image(s) selected", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.fvPrimary)
                    .onChange(of: selectedItems) { _, newItems in
                        loadImages(from: newItems)
                    }

                    if !images.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: FVSpacing.sm) {
                                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 70, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                                }
                            }
                        }
                    }

                    TextField("File name", text: $name)
                        .autocorrectionDisabled()
                        .padding(FVSpacing.md)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.danger)
                    }

                    Spacer()
                }
                .padding(FVSpacing.md)
            }
            .navigationTitle("PDF from Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { confirm() }
                        .foregroundStyle(FVColor.accent)
                        .disabled(images.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loaded: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    loaded.append(image)
                }
            }
            await MainActor.run {
                images = loaded
                if loaded.isEmpty { errorMessage = String(localized: "Could not load images.") } else { errorMessage = nil }
            }
        }
    }

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !images.isEmpty, !trimmed.isEmpty else { return }
        onConfirm(images, trimmed)
        dismiss()
    }
}
