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
        let picker = PendingImportQueueView(
            items: items,
            onComplete: { [weak self] in
                self?.openMainApp()
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

    private func openMainApp() {
        guard let url = URL(string: "filemanager://import") else { return }
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        while let current = responder {
            if current.responds(to: selector) {
                current.perform(selector, with: url)
                return
            }
            responder = current.next
        }
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

        let resultsLock = NSLock()
        var results: [ShareItem] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            loadFile(from: provider) { item in
                if let item {
                    resultsLock.lock()
                    results.append(item)
                    resultsLock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    private func loadFile(from provider: NSItemProvider, completion: @escaping (ShareItem?) -> Void) {
        let identifiers = provider.registeredTypeIdentifiers
        guard !identifiers.isEmpty else {
            completion(nil)
            return
        }
        tryLoad(from: provider, identifiers: identifiers, index: 0, completion: completion)
    }

    private func tryLoad(from provider: NSItemProvider, identifiers: [String], index: Int, completion: @escaping (ShareItem?) -> Void) {
        guard index < identifiers.count else {
            completion(nil)
            return
        }
        provider.loadFileRepresentation(forTypeIdentifier: identifiers[index]) { [weak self] url, error in
            guard let self else { return }
            guard let url, error == nil else {
                self.tryLoad(from: provider, identifiers: identifiers, index: index + 1, completion: completion)
                return
            }
            let fileExtension = url.pathExtension.isEmpty ? "dat" : url.pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                completion(ShareItem(suggestedName: url.lastPathComponent, temporaryURL: tempURL))
            } catch {
                self.tryLoad(from: provider, identifiers: identifiers, index: index + 1, completion: completion)
            }
        }
    }
}
