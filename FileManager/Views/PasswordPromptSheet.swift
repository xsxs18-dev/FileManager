import SwiftUI

struct PasswordPromptSheet: View {
    let title: String
    let message: String?
    let confirmTitle: String
    let requiresConfirmation: Bool
    let onConfirm: (String) -> Void

    @State private var password = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        requiresConfirmation: Bool = false,
        onConfirm: @escaping (String) -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.requiresConfirmation = requiresConfirmation
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: FVSpacing.md) {
                    if let message {
                        Text(message)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.textSecondary)
                    }

                    SecureField("Password", text: $password)
                        .focused($isFocused)
                        .padding(FVSpacing.md)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)

                    if requiresConfirmation {
                        SecureField("Confirm Password", text: $confirmation)
                            .padding(FVSpacing.md)
                            .background(FVColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                            .foregroundStyle(FVColor.textPrimary)
                    }

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
                        .disabled(password.isEmpty)
                }
            }
        }
        .presentationDetents([.height(requiresConfirmation ? 260 : 200)])
        .onAppear { isFocused = true }
    }

    private func confirm() {
        if requiresConfirmation && password != confirmation {
            errorMessage = "Passwords do not match."
            return
        }
        onConfirm(password)
        dismiss()
    }
}
