import SwiftUI

struct HiddenAreaView: View {
    @ObservedObject private var protectionStore = FolderProtectionStore.shared
    @State private var items: [FileItem] = []

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            if items.isEmpty {
                VStack(spacing: FVSpacing.sm) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(FVColor.textSecondary)
                    Text("No hidden folders")
                        .font(FVFont.body)
                        .foregroundStyle(FVColor.textSecondary)
                }
            } else {
                List {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: FVSpacing.md) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(FVColor.accent)
                                    .frame(width: 28)
                                Text(item.name)
                                    .foregroundStyle(FVColor.textPrimary)
                                Spacer()
                                if protectionStore.isLocked(item.url) {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(FVColor.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(FVColor.background)
                        .swipeActions(edge: .trailing) {
                            Button {
                                protectionStore.setHidden(false, for: item.url)
                                reload()
                            } label: {
                                Label("Unhide", systemImage: "eye")
                            }
                            .tint(FVColor.accent)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Hidden Area")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .navigationDestination(for: FileItem.self) { item in
            FolderDestinationView(item: item)
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        items = protectionStore.hiddenFolderItems()
    }
}
