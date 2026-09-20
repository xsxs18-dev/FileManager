import Foundation

enum AppGroup {
    static let identifier = "group.com.xsxs18.FileManager"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        return url
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
