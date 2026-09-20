import SwiftUI

struct NameInputSheet: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    let initialValue: String
    let confirmTitle: LocalizedStringKey
    let onConfirm: (String) -> Void

    @State private var name: String
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        initialValue: String = "",
        confirmTitle: LocalizedStringKey = "Create",
        onConfirm: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.initialValue = initialValue
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        _name = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: FVSpacing.md) {
                    TextField(placeholder, text: $name)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle) { confirm() }
                        .foregroundStyle(FVColor.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(180)])
        .onAppear { isFocused = true }
    }

    private func confirm() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onConfirm(trimmed)
        dismiss()
    }
}
