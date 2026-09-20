import SwiftUI
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct FilePreviewSheet: View {
    let item: FileItem
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            QuickLookPreview(url: item.url)
                .ignoresSafeArea()
                .navigationTitle(item.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FVColor.background, for: .navigationBar)
                .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { onClose() }
                            .foregroundStyle(FVColor.accent)
                    }
                }
        }
    }
}
