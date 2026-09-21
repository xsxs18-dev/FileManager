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
        .onAppear(perform: handleForeground)
        .onOpenURL { _ in handleForeground() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleForeground()
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

    private func handleForeground() {
        FolderIndexStore.publish(relativePaths: FileSystemService.shared.allFolderPaths())
        importPending()
    }

    private func importPending() {
        let pending = PendingImportStore.takePending()
        guard !pending.isEmpty else { return }

        let root = FileSystemService.shared.rootURL
        var imported = 0
        for item in pending {
            let destination = resolvedDirectory(for: item.destinationPath, root: root)
            let name = FileSystemService.shared.uniqueName(for: item.name, in: destination)
            if (try? FileSystemService.shared.createFile(named: name, in: destination, contents: item.data)) != nil {
                imported += 1
            }
        }
        if imported > 0 {
            importMessage = String(localized: "Brought in \(imported) file(s) shared from another app.")
        }
    }

    private func resolvedDirectory(for relativePath: String, root: URL) -> URL {
        guard !relativePath.isEmpty else { return root }
        let candidate = root.appendingPathComponent(relativePath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return root
        }
        return candidate
    }
}
