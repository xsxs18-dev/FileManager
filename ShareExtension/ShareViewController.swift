import UIKit
import SwiftUI

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        extractAttachments { [weak self] items in
            DispatchQueue.main.async {
                self?.presentPicker(for: items)
            }
        }
    }

    private func presentPicker(for items: [ShareItem]) {
        let picker = FolderPickerView(
            items: items,
            onComplete: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                let error = NSError(domain: "com.xsxs18.FileManager.ShareExtension", code: -1)
                self?.extensionContext?.cancelRequest(withError: error)
            }
        )
        let hosting = UIHostingController(rootView: picker)
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }

    private func extractAttachments(completion: @escaping ([ShareItem]) -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion([])
            return
        }
        let providers = extensionItems.compactMap { $0.attachments }.flatMap { $0 }
        guard !providers.isEmpty else {
            completion([])
            return
        }

        var results: [ShareItem] = []
        let group = DispatchGroup()

        for provider in providers {
            guard let identifier = provider.registeredTypeIdentifiers.first else { continue }
            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: identifier) { url, error in
                defer { group.leave() }
                guard let url, error == nil else { return }
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                try? FileManager.default.copyItem(at: url, to: tempURL)
                results.append(ShareItem(suggestedName: url.lastPathComponent, temporaryURL: tempURL))
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }
}
