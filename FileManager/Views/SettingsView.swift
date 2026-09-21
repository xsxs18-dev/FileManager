import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var protectionStore = FolderProtectionStore.shared
    @State private var updateResult: UpdateCheckResult?
    @State private var updateError: String?
    @State private var isChecking = false
    @State private var secretTapCount = 0
    @State private var lastSecretTap = Date.distantPast
    @State private var showSecretVault = false
    @State private var versionTapCount = 0
    @State private var lastVersionTap = Date.distantPast
    @State private var showThresholdSheet = false

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            List {
                Section {
                    Button {
                        registerSecretTap()
                    } label: {
                        VStack(spacing: FVSpacing.sm) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(FVColor.accent)
                            Text("FileManager")
                                .font(FVFont.headline)
                                .foregroundStyle(FVColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FVSpacing.md)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(FVColor.background)
                }

                Section {
                    ForEach(FVThemeID.allCases) { id in
                        themeRow(for: id)
                    }
                } header: {
                    Text("Appearance")
                        .foregroundStyle(FVColor.textSecondary)
                }
                .listRowBackground(FVColor.surface)

                Section {
                    Toggle("Secure Delete", isOn: Binding(
                        get: { protectionStore.isSecureShredEnabled },
                        set: { protectionStore.setSecureShredEnabled($0) }
                    ))
                    .tint(FVColor.accent)
                    .foregroundStyle(FVColor.textPrimary)
                } header: {
                    Text("Security")
                        .foregroundStyle(FVColor.textSecondary)
                } footer: {
                    Text("Secure Delete overwrites a file's data with random bytes before removing it, so it's much harder to recover afterward. Slower than a normal delete, especially for large files.")
                        .foregroundStyle(FVColor.textSecondary)
                }
                .listRowBackground(FVColor.surface)

                Section {
                    Button {
                        registerVersionTap()
                    } label: {
                        HStack {
                            Text("Version")
                                .foregroundStyle(FVColor.textPrimary)
                            Spacer()
                            Text(currentVersionLabel)
                                .foregroundStyle(FVColor.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        checkForUpdate()
                    } label: {
                        HStack {
                            Text(isChecking ? "Checking…" : "Check for Updates")
                            Spacer()
                            if isChecking {
                                ProgressView()
                            }
                        }
                    }
                    .foregroundStyle(FVColor.accent)
                    .disabled(isChecking)

                    NavigationLink {
                        ChangelogView()
                    } label: {
                        Text("Changelog")
                            .foregroundStyle(FVColor.accent)
                    }

                    if let updateResult {
                        if updateResult.isUpdateAvailable {
                            Link(destination: updateResult.releaseURL) {
                                VStack(alignment: .leading, spacing: FVSpacing.xs) {
                                    Text("Update available: build \(updateResult.latestVersion)")
                                        .foregroundStyle(FVColor.accent)
                                    Text("Tap to open the release on GitHub and install it there.")
                                        .font(FVFont.caption)
                                        .foregroundStyle(FVColor.textSecondary)
                                }
                            }
                        } else {
                            Text("You're up to date.")
                                .foregroundStyle(FVColor.textSecondary)
                        }
                    }

                    if let updateError {
                        Text(updateError)
                            .foregroundStyle(FVColor.danger)
                    }
                } header: {
                    Text("Updates")
                        .foregroundStyle(FVColor.textSecondary)
                } footer: {
                    Text("These are the only network requests FileManager ever makes — checking GitHub for release info and nothing else.")
                        .foregroundStyle(FVColor.textSecondary)
                }
                .listRowBackground(FVColor.surface)

                Section {
                    Text("Files shared here from other apps land in My Files the next time FileManager is opened.")
                        .foregroundStyle(FVColor.textSecondary)
                } header: {
                    Text("Share Sheet")
                        .foregroundStyle(FVColor.textSecondary)
                }
                .listRowBackground(FVColor.surface)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .fullScreenCover(isPresented: $showSecretVault) {
            SecretVaultGateView()
        }
        .sheet(isPresented: $showThresholdSheet) {
            SelfDestructThresholdSheet {}
        }
    }

    private func themeRow(for id: FVThemeID) -> some View {
        let theme = FVTheme.theme(for: id)
        return Button {
            themeManager.select(id)
        } label: {
            HStack(spacing: FVSpacing.md) {
                HStack(spacing: -6) {
                    Circle().fill(theme.accent).frame(width: 22, height: 22)
                    Circle().fill(theme.background).frame(width: 22, height: 22)
                        .overlay(Circle().stroke(FVColor.border, lineWidth: 1))
                }
                Text(id.displayName)
                    .foregroundStyle(FVColor.textPrimary)
                Spacer()
                if themeManager.current.id == id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(FVColor.accent)
                }
            }
        }
    }

    private var currentVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev"
        return "\(version) (build \(build))"
    }

    private func registerSecretTap() {
        let now = Date()
        if now.timeIntervalSince(lastSecretTap) > 2.5 {
            secretTapCount = 0
        }
        lastSecretTap = now
        secretTapCount += 1
        if secretTapCount >= 7 {
            secretTapCount = 0
            showSecretVault = true
        }
    }

    private func registerVersionTap() {
        let now = Date()
        if now.timeIntervalSince(lastVersionTap) > 2.5 {
            versionTapCount = 0
        }
        lastVersionTap = now
        versionTapCount += 1
        if versionTapCount >= 10 {
            versionTapCount = 0
            showThresholdSheet = true
        }
    }

    private func checkForUpdate() {
        isChecking = true
        updateError = nil
        Task {
            do {
                let result = try await UpdateChecker.shared.checkForUpdate()
                await MainActor.run {
                    updateResult = result
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    updateError = error.localizedDescription
                    isChecking = false
                }
            }
        }
    }
}
