import SwiftUI

enum FVThemeID: String, CaseIterable, Codable, Identifiable {
    case lightBlueDark
    case redDark
    case lightBlueLight
    case redLight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lightBlueDark: return String(localized: "Light Blue & Black")
        case .redDark: return String(localized: "Red & Black")
        case .lightBlueLight: return String(localized: "Light Blue & White")
        case .redLight: return String(localized: "Red & White")
        }
    }
}

struct FVTheme {
    let id: FVThemeID
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let border: Color
    let accent: Color
    let accentMuted: Color
    let textPrimary: Color
    let textSecondary: Color
    let danger: Color
    let colorScheme: ColorScheme

    static let lightBlueDark = FVTheme(
        id: .lightBlueDark,
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x121212),
        surfaceElevated: Color(hex: 0x1C1C1E),
        border: Color(hex: 0x2C2C2E),
        accent: Color(hex: 0x4CC2FF),
        accentMuted: Color(hex: 0x4CC2FF, alpha: 0.16),
        textPrimary: .white,
        textSecondary: Color(hex: 0x9A9A9E),
        danger: Color(hex: 0xFF453A),
        colorScheme: .dark
    )

    static let redDark = FVTheme(
        id: .redDark,
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x121212),
        surfaceElevated: Color(hex: 0x1C1C1E),
        border: Color(hex: 0x2C2C2E),
        accent: Color(hex: 0xFF3B30),
        accentMuted: Color(hex: 0xFF3B30, alpha: 0.16),
        textPrimary: .white,
        textSecondary: Color(hex: 0x9A9A9E),
        danger: Color(hex: 0xFF453A),
        colorScheme: .dark
    )

    static let lightBlueLight = FVTheme(
        id: .lightBlueLight,
        background: Color(hex: 0xFFFFFF),
        surface: Color(hex: 0xF2F2F7),
        surfaceElevated: Color(hex: 0xE5E5EA),
        border: Color(hex: 0xD1D1D6),
        accent: Color(hex: 0x4CC2FF),
        accentMuted: Color(hex: 0x4CC2FF, alpha: 0.16),
        textPrimary: .black,
        textSecondary: Color(hex: 0x6E6E73),
        danger: Color(hex: 0xD70015),
        colorScheme: .light
    )

    static let redLight = FVTheme(
        id: .redLight,
        background: Color(hex: 0xFFFFFF),
        surface: Color(hex: 0xF2F2F7),
        surfaceElevated: Color(hex: 0xE5E5EA),
        border: Color(hex: 0xD1D1D6),
        accent: Color(hex: 0xFF3B30),
        accentMuted: Color(hex: 0xFF3B30, alpha: 0.16),
        textPrimary: .black,
        textSecondary: Color(hex: 0x6E6E73),
        danger: Color(hex: 0xD70015),
        colorScheme: .light
    )

    static func theme(for id: FVThemeID) -> FVTheme {
        switch id {
        case .lightBlueDark: return .lightBlueDark
        case .redDark: return .redDark
        case .lightBlueLight: return .lightBlueLight
        case .redLight: return .redLight
        }
    }
}
