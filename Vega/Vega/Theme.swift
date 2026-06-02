import SwiftUI

// MARK: - Theme
/// Single source of truth for all design tokens in Vera.
/// Never hardcode colors, fonts or radii elsewhere.
enum Theme {

    // MARK: Colors
    static let primary       = Color("azulfuerte")
    static let primaryLight  = Color(hex: "#EFF6FF")
    static let primaryMid    = Color(hex: "#93C5FD")

    static let danger        = Color(hex: "#EF4444")
    static let dangerLight   = Color(hex: "#FEF2F2")

    static let warning       = Color("azulfuerte")
    static let warningLight  = Color(hex: "#FFFBEB")

    static let success       = Color(hex: "#10B981")
    static let successLight  = Color(hex: "#ECFDF5")

    static let blue       = Color("#0E275A")
    static let blueligth   = Color(hex: "#E8F3FE")

    static let surface       = Color(.white)
    static let surfaceAlt    = Color(hex: "#F1EFE8")
    static let border        = Color(hex: "#E5E7EB")

    static let textPrimary   = Color(hex: "#111827")
    static let textSecondary = Color(hex: "#6B7280")
    static let textBlue = Color(hex: "#0E275A")
    static let textTertiary  = Color("palabras")

    // MARK: Meltdown type colors
    static func color(for type: MeltdownType) -> Color {
        switch type {
        case .sobreestimulacion: return Color("verde")
        case .frustracion:       return Color(hex: "#EF4444")
        case .cansancio:         return Color(hex: "#7C3AED")
        case .cambioRutina:      return Color(hex: "#2563EB")
        }
    }

    static func lightColor(for type: MeltdownType) -> Color {
        switch type {
        case .sobreestimulacion: return Color(hex: "#FFFBEB")
        case .frustracion:       return Color(hex: "#FEF2F2")
        case .cansancio:         return Color(hex: "#F5F3FF")
        case .cambioRutina:      return Color(hex: "#EFF6FF")
        }
    }

    // MARK: Typography
    static func titleFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headlineFont(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func bodyFont(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func captionFont(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: Spacing & Shape
    static let spacingS:  CGFloat = 8
    static let spacingM:  CGFloat = 16
    static let spacingL:  CGFloat = 24
    static let cornerS:   CGFloat = 10
    static let cornerM:   CGFloat = 14
    static let cornerL:   CGFloat = 20
}

// MARK: - Color(hex:)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
