import SwiftUI

struct FolderDestinationView: View {
    let item: FileItem

    var body: some View {
        if item.isDirectory && FolderProtectionStore.shared.isLocked(item.url) {
            LockedFolderGateView(item: item)
        } else {
            FileBrowserView(directory: item.url, title: item.name)
        }
    }
}
