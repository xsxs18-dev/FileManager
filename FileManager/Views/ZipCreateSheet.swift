import SwiftUI

struct ZipCreateSheet: View {
    let itemCount: Int
    let onConfirm: (_ name: String, _ password: String?) -> Void

    @State private var name = "Archive"
    @State private var useEncryption = false
    @State private var password = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: FVSpacing.md) {
                    Text("\(itemCount) item(s) will be zipped")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)

                    TextField("Archive name", text: $name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(FVSpacing.md)
                        .background(FVColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                        .foregroundStyle(FVColor.textPrimary)

                    Toggle("Encrypt with password (AES-256)", isOn: $useEncryption.animation())
                        .tint(FVColor.accent)
                        .foregroundStyle(FVColor.textPrimary)

                    if useEncryption {
                        SecureField("Password", text: $password)
                            .padding(FVSpacing.md)
                            .background(FVColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
                            .foregroundStyle(FVColor.textPrimary)

                        SecureField("Confirm password", text: $confirmation)
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
            .navigationTitle("Create Zip")
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
        .presentationDetents([.height(useEncryption ? 420 : 260)])
    }

    private func confirm() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        if useEncryption {
            guard !password.isEmpty else {
                errorMessage = "Please enter a password."
                return
            }
            guard password == confirmation else {
                errorMessage = "Passwords do not match."
                return
            }
        }
        onConfirm(trimmedName, useEncryption ? password : nil)
        dismiss()
    }
}
