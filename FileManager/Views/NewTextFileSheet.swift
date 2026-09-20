import SwiftUI

struct NewTextFileSheet: View {
    let onConfirm: (_ name: String, _ content: String) -> Void

    @State private var name = "New File.txt"
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(spacing: FVSpacing.md) {
                    TextField("File name", text: $name)
                        .autocorrectionDisabled()
                        .padding(FVSpacing.md)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)

                    TextEditor(text: $content)
                        .scrollContentBackground(.hidden)
                        .padding(FVSpacing.sm)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)
                }
                .padding(FVSpacing.md)
            }
            .navigationTitle("New Text File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { confirm() }
                        .foregroundStyle(FVColor.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func confirm() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        onConfirm(trimmedName, content)
        dismiss()
    }
}
