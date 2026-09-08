import UIKit

// MARK: - UIColor Theme Extension
// App color palette and convenience initializers.

extension UIColor {

    /// Initialize a UIColor from a hex string (e.g., "#00D4FF" or "00D4FF").
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        switch length {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255
            b = CGFloat(rgb & 0x0000FF) / 255
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255
            a = CGFloat(rgb & 0x000000FF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - App Theme Colors

    /// Primary accent color (cyan)
    static let accent = UIColor(hex: "#00D4FF")

    /// Background color (near black)
    static let background = UIColor(hex: "#0A0A0F")

    /// Secondary background (slightly lighter)
    static let secondaryBackground = UIColor(hex: "#141420")

    /// Surface color for cards
    static let surface = UIColor.white.withAlphaComponent(0.06)

    /// Surface border
    static let surfaceBorder = UIColor.white.withAlphaComponent(0.1)

    /// Warning color
    static let warning = UIColor(hex: "#FF6B6B")

    /// Success color
    static let success = UIColor(hex: "#4CAF50")

    /// Tip/info color
    static let tip = UIColor(hex: "#FFD700")

    /// Easy difficulty
    static let easy = UIColor(hex: "#4CAF50")

    /// Moderate difficulty
    static let moderate = UIColor(hex: "#FF9800")

    /// Difficult difficulty
    static let difficult = UIColor(hex: "#F44336")

    /// Expert difficulty
    static let expert = UIColor(hex: "#9C27B0")

    // MARK: - Component State Colors

    /// Current focus glow (bright cyan)
    static let focusGlow = UIColor(hex: "#00D4FF")

    /// Completed component (dimmed)
    static let completed = UIColor.white.withAlphaComponent(0.1)

    /// Not yet reached (subtle)
    static let notReached = UIColor.white.withAlphaComponent(0.2)

    /// Highlight on tap (gold)
    static let highlight = UIColor(hex: "#FFD700")
}
