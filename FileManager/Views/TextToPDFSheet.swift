import SwiftUI

struct TextToPDFSheet: View {
    let onConfirm: (_ text: String, _ name: String) -> Void

    @State private var text = ""
    @State private var name = "Note"
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

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .padding(FVSpacing.sm)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)
                }
                .padding(FVSpacing.md)
            }
            .navigationTitle("PDF from Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") { confirm() }
                        .foregroundStyle(FVColor.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func confirm() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        onConfirm(text, trimmedName)
        dismiss()
    }
}
