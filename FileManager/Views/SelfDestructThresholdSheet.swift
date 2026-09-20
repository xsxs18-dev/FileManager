import SwiftUI

struct SelfDestructThresholdSheet: View {
    let onComplete: () -> Void

    @ObservedObject private var protectionStore = FolderProtectionStore.shared
    @Environment(\.dismiss) private var dismiss

    private let options = [0, 3, 5, 10]

    var body: some View {
        NavigationStack {
            ZStack {
                FVColor.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: FVSpacing.md) {
                    Text("Delete a locked folder — or the secret vault — automatically after this many wrong Face ID attempts in a row. A cancelled prompt never counts.")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)

                    ForEach(options, id: \.self) { limit in
                        Button {
                            protectionStore.setFailedAttemptLimit(limit)
                        } label: {
                            HStack {
                                Text(limit == 0 ? "Never" : "\(limit) Attempts")
                                    .foregroundStyle(FVColor.textPrimary)
                                Spacer()
                                if protectionStore.failedAttemptLimit == limit {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(FVColor.accent)
                                }
                            }
                            .padding(FVSpacing.md)
                            .fvCard()
                        }
                    }
                    Spacer()
                }
                .padding(FVSpacing.md)
            }
            .navigationTitle("Self-Destruct Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FVColor.background, for: .navigationBar)
            .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete()
                        dismiss()
                    }
                    .foregroundStyle(FVColor.accent)
                }
            }
        }
    }
}
