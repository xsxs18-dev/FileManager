import SwiftUI

@main
struct FileManagerApp: App {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .id(themeManager.current.id)
                .preferredColorScheme(themeManager.current.colorScheme)
                .tint(themeManager.current.accent)
        }
    }
}
