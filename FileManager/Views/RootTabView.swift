import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }

            NavigationStack {
                PDFCreatorView()
            }
            .tabItem {
                Label("PDF Creator", systemImage: "doc.richtext.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(FVColor.accent)
    }
}
