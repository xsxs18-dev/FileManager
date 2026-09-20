import SwiftUI

struct SecretVaultGateView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isUnlocked = false
    @State private var wasDeleted = false
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        Group {
            if isUnlocked {
                NavigationStack {
                    FileBrowserView(directory: FileSystemService.shared.secretRootURL, title: String(localized: "Secret Vault"))
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { dismiss() }
                                    .foregroundStyle(FVColor.accent)
                            }
                        }
                }
            } else if wasDeleted {
                deletedScreen
            } else {
                lockScreen
            }
        }
        .task {
            await authenticate()
        }
    }

    private var lockScreen: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(spacing: FVSpacing.lg) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FVColor.accent)
                    Text("Secret Vault")
                        .font(FVFont.headline)
                        .foregroundStyle(FVColor.textPrimary)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, FVSpacing.lg)
                    }
                    Button("Unlock with Face ID") {
                        Task { await authenticate() }
                    }
                    .buttonStyle(.fvPrimary)
                    .disabled(isAuthenticating)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
    }

    private var deletedScreen: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(spacing: FVSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(FVColor.danger)
                    Text("Secret Vault Deleted")
                        .font(FVFont.headline)
                        .foregroundStyle(FVColor.textPrimary)
                    Text("The secret vault was wiped after too many failed unlock attempts.")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FVSpacing.lg)
                    Button("Close") { dismiss() }
                        .buttonStyle(.fvPrimary)
                }
            }
        }
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        errorMessage = nil
        let secretRoot = FileSystemService.shared.secretRootURL
        do {
            try await AuthenticationService.shared.authenticate(reason: "Unlock Secret Vault")
            FolderProtectionStore.shared.resetFailedAttempts(for: secretRoot)
            isUnlocked = true
        } catch AuthenticationError.cancelled {
            isAuthenticating = false
            return
        } catch {
            errorMessage = error.localizedDescription
            if FolderProtectionStore.shared.registerFailedAttempt(for: secretRoot) {
                try? FileManager.default.removeItem(at: secretRoot)
                wasDeleted = true
            }
        }
        isAuthenticating = false
    }
}
