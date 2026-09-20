import SwiftUI

@main
struct FileManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(FVColor.accent)
        }
    }
}
