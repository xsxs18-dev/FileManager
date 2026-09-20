import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

enum FVColor {
    static let background = Color(hex: 0x000000)
    static let surface = Color(hex: 0x121212)
    static let surfaceElevated = Color(hex: 0x1C1C1E)
    static let border = Color(hex: 0x2C2C2E)
    static let accent = Color(hex: 0x4CC2FF)
    static let accentMuted = Color(hex: 0x4CC2FF, alpha: 0.16)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x9A9A9E)
    static let danger = Color(hex: 0xFF6B6B)
}

enum FVSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum FVRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
}

enum FVFont {
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .default)
}

struct FVPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FVFont.headline)
            .foregroundStyle(Color.black)
            .padding(.vertical, FVSpacing.sm)
            .padding(.horizontal, FVSpacing.md)
            .background(FVColor.accent.opacity(configuration.isPressed ? 0.7 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: FVRadius.sm, style: .continuous))
    }
}

struct FVIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FVColor.accent)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct FVCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(FVColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FVRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FVRadius.md, style: .continuous)
                    .stroke(FVColor.border, lineWidth: 1)
            )
    }
}

extension View {
    func fvCard() -> some View {
        modifier(FVCardBackground())
    }
}

extension ButtonStyle where Self == FVPrimaryButtonStyle {
    static var fvPrimary: FVPrimaryButtonStyle { FVPrimaryButtonStyle() }
}

extension ButtonStyle where Self == FVIconButtonStyle {
    static var fvIcon: FVIconButtonStyle { FVIconButtonStyle() }
}
