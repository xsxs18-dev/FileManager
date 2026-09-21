import SwiftUI

struct ChangelogView: View {
    @State private var entries: [ChangelogEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                VStack(spacing: FVSpacing.md) {
                    Text(errorMessage)
                        .foregroundStyle(FVColor.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FVSpacing.lg)
                    Button("Retry") { load() }
                        .foregroundStyle(FVColor.accent)
                }
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: FVSpacing.xs) {
                        HStack {
                            Text(entry.displayVersion)
                                .font(FVFont.headline)
                                .foregroundStyle(FVColor.textPrimary)
                            Spacer()
                            if let date = entry.displayDate {
                                Text(date)
                                    .font(FVFont.caption)
                                    .foregroundStyle(FVColor.textSecondary)
                            }
                        }
                        Text(entry.displayChanges)
                            .font(FVFont.body)
                            .foregroundStyle(FVColor.textSecondary)
                    }
                    .padding(.vertical, FVSpacing.xs)
                    .listRowBackground(FVColor.surface)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Changelog")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .onAppear {
            if entries.isEmpty { load() }
        }
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await UpdateChecker.shared.fetchChangelog()
                await MainActor.run {
                    entries = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
