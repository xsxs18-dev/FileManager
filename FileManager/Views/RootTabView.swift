import SwiftUI
import UIKit

struct RootTabView: View {
    @State private var selectedTab = 0
    @State private var filesRevision = UUID()
    @State private var importMessage: String?
    @State private var importError: String?
    @State private var importingURLs: Set<URL> = []

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .id(filesRevision)
                .tabItem {
                    Label("Files", systemImage: "folder.fill")
                }
                .tag(0)

            NavigationStack {
                PDFCreatorView()
            }
            .tabItem {
                Label("PDF Creator", systemImage: "doc.richtext.fill")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(FVColor.accent)
        .onOpenURL { url in
            if url.isFileURL { importFile(url) }
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
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

    private func importFile(_ url: URL) {
        guard importingURLs.insert(url).inserted else { return }
        Task { @MainActor in
            defer { importingURLs.remove(url) }
            do {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let root = FileSystemService.shared.rootURL
                let name = FileSystemService.shared.uniqueName(for: url.lastPathComponent, in: root)
                let destination = root.appendingPathComponent(name)
                try await Task.detached(priority: .userInitiated) {
                    let coordinator = NSFileCoordinator()
                    var coordinationError: NSError?
                    var copyError: Error?
                    coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
                        do { try FileManager.default.copyItem(at: readableURL, to: destination) }
                        catch { copyError = error }
                    }
                    if let coordinationError { throw coordinationError }
                    if let copyError { throw copyError }
                }.value
                filesRevision = UUID()
                selectedTab = 0
                importMessage = String(localized: "File imported into My Files.")
            } catch {
                importError = error.localizedDescription
            }
        }
    }

}
