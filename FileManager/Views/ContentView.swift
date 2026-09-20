import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            FileBrowserView(directory: FileSystemService.shared.rootURL, title: String(localized: "My Files"))
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
                    FolderDestinationView(item: item)
                }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
