import SwiftUI

struct LockedFolderGateView: View {
    let item: FileItem

    @State private var isUnlocked = false
    @State private var wasDeleted = false
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if isUnlocked {
                FileBrowserView(directory: item.url, title: item.name)
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
        ZStack {
            FVColor.background.ignoresSafeArea()
            VStack(spacing: FVSpacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FVColor.accent)
                Text(item.name)
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
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
    }

    private var deletedScreen: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            VStack(spacing: FVSpacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(FVColor.danger)
                Text("Folder Deleted")
                    .font(FVFont.headline)
                    .foregroundStyle(FVColor.textPrimary)
                Text("\"\(item.name)\" was deleted after too many failed unlock attempts.")
                    .font(FVFont.caption)
                    .foregroundStyle(FVColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, FVSpacing.lg)
                Button("Close") { dismiss() }
                    .buttonStyle(.fvPrimary)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        errorMessage = nil
        do {
            try await AuthenticationService.shared.authenticate(reason: "Unlock \"\(item.name)\"")
            FolderProtectionStore.shared.resetFailedAttempts(for: item.url)
            isUnlocked = true
        } catch AuthenticationError.cancelled {
            isAuthenticating = false
            return
        } catch {
            errorMessage = error.localizedDescription
            if FolderProtectionStore.shared.registerFailedAttempt(for: item.url) {
                try? FileSystemService.shared.delete(item)
                wasDeleted = true
            }
        }
        isAuthenticating = false
    }
}
