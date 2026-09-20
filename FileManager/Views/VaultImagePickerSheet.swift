import SwiftUI
import UIKit

struct VaultImagePickerSheet: View {
    let onConfirm: (_ images: [UIImage], _ name: String) -> Void

    @State private var items: [FileItem] = []
    @State private var selection: [FileItem] = []
    @State private var name = "Document"
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                if isLoading {
                    ProgressView()
                        .tint(FVColor.accent)
                } else if items.isEmpty {
                    VStack(spacing: FVSpacing.sm) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundStyle(FVColor.textSecondary)
                        Text("No images found in your files")
                            .foregroundStyle(FVColor.textSecondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: FVSpacing.sm)], spacing: FVSpacing.sm) {
                                ForEach(items) { item in
                                    thumbnail(for: item)
                                }
                            }
                            .padding(FVSpacing.md)
                        }

                        TextField("File name", text: $name)
                            .autocorrectionDisabled()
                            .padding(FVSpacing.md)
                            .background(FVColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                            .foregroundStyle(FVColor.textPrimary)
                            .padding(.horizontal, FVSpacing.md)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(FVFont.caption)
                                .foregroundStyle(FVColor.danger)
                        }

                        Button {
                            confirm()
                        } label: {
                            Text("Create PDF (\(selection.count) selected)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.fvPrimary)
                        .padding(FVSpacing.md)
                        .disabled(selection.isEmpty || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Select Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FVColor.background, for: .navigationBar)
            .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
        .onAppear(perform: load)
    }

    private func thumbnail(for item: FileItem) -> some View {
        let isSelected = selection.contains(item)
        return Button {
            toggle(item)
        } label: {
            ZStack(alignment: .topTrailing) {
                if let data = try? Data(contentsOf: item.url), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous)
                        .fill(FVColor.surface)
                        .frame(width: 90, height: 90)
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(FVColor.accent)
                        .background(Circle().fill(FVColor.background))
                        .padding(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous)
                    .stroke(isSelected ? FVColor.accent : .clear, lineWidth: 2)
            )
        }
    }

    private func toggle(_ item: FileItem) {
        if let index = selection.firstIndex(of: item) {
            selection.remove(at: index)
        } else {
            selection.append(item)
        }
    }

    private func load() {
        items = FileSystemService.shared.allImageFiles(in: FileSystemService.shared.rootURL)
        isLoading = false
    }

    private func confirm() {
        let images = selection.compactMap { item -> UIImage? in
            guard let data = try? Data(contentsOf: item.url) else { return nil }
            return UIImage(data: data)
        }
        guard !images.isEmpty else {
            errorMessage = String(localized: "Could not load the selected images.")
            return
        }
        onConfirm(images, name.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}
