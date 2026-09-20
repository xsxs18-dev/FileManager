import SwiftUI

struct LockedFolderGateView: View {
    let item: FileItem

    @State private var isUnlocked = false
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        Group {
            if isUnlocked {
                FileBrowserView(directory: item.url, title: item.name)
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

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        errorMessage = nil
        do {
            try await AuthenticationService.shared.authenticate(reason: "Unlock \"\(item.name)\"")
            isUnlocked = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isAuthenticating = false
    }
}
