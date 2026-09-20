import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var current: FVTheme

    private let defaults = UserDefaults.standard
    private let key = "FileManager.selectedTheme"

    private init() {
        if let raw = defaults.string(forKey: key), let id = FVThemeID(rawValue: raw) {
            current = FVTheme.theme(for: id)
        } else {
            current = .lightBlueDark
        }
    }

    func select(_ id: FVThemeID) {
        current = FVTheme.theme(for: id)
        defaults.set(id.rawValue, forKey: key)
    }
}
