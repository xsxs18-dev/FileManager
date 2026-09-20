import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            FileBrowserView(directory: FileSystemService.shared.rootURL, title: "Meine Dateien")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            HiddenAreaView()
                        } label: {
                            Image(systemName: "eye.slash.fill")
                                .foregroundStyle(FVColor.accent)
                        }
                    }
                }
                .navigationDestination(for: FileItem.self) { item in
                    if item.isDirectory && FolderProtectionStore.shared.isLocked(item.url) {
                        LockedFolderGateView(item: item)
                    } else {
                        FileBrowserView(directory: item.url, title: item.name)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
