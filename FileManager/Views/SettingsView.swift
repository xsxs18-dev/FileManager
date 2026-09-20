import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var updateResult: UpdateCheckResult?
    @State private var updateError: String?
    @State private var isChecking = false

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            List {
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
                    HStack {
                        Text("Version")
                            .foregroundStyle(FVColor.textPrimary)
                        Spacer()
                        Text(currentVersionLabel)
                            .foregroundStyle(FVColor.textSecondary)
                    }

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
                    Text("This is the only network request FileManager ever makes — it checks GitHub for the latest release tag and sends nothing else.")
                        .foregroundStyle(FVColor.textSecondary)
                }
                .listRowBackground(FVColor.surface)

                Section {
                    HStack {
                        Text("Share Extension storage")
                            .foregroundStyle(FVColor.textPrimary)
                        Spacer()
                        Label(
                            AppGroup.isAvailable ? "Working" : "Not working",
                            systemImage: AppGroup.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(AppGroup.isAvailable ? FVColor.accent : FVColor.danger)
                    }
                } footer: {
                    if !AppGroup.isAvailable {
                        Text("Files shared into FileManager from other apps won't show up here. This is usually a sideload signing issue — re-signing with your own Apple Developer account, or opening the project once in Xcode with your Apple ID, generally fixes it.")
                            .foregroundStyle(FVColor.textSecondary)
                    }
                }
                .listRowBackground(FVColor.surface)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
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
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "dev"
        return String(localized: "build \(build)")
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
