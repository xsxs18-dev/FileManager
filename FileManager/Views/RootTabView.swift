import SwiftUI
import UIKit

struct RootTabView: View {
    @State private var importMessage: String?

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
        .onAppear(perform: importPending)
        .onOpenURL { _ in importPending() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            importPending()
        }
        .alert("Import Complete", isPresented: Binding(
            get: { importMessage != nil },
            set: { isPresented in if !isPresented { importMessage = nil } }
        ), presenting: importMessage) { _ in
            Button("OK") { importMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func importPending() {
        let pending = PendingImportStore.takePending()
        guard !pending.isEmpty else { return }

        let root = FileSystemService.shared.rootURL
        var imported = 0
        for item in pending {
            let name = FileSystemService.shared.uniqueName(for: item.name, in: root)
            if (try? FileSystemService.shared.createFile(named: name, in: root, contents: item.data)) != nil {
                imported += 1
            }
        }
        if imported > 0 {
            importMessage = String(localized: "Brought in \(imported) file(s) shared from another app. They're in My Files.")
        }
    }
}
