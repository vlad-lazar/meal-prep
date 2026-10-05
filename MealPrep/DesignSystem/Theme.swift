import SwiftUI
import UIKit
import MealPrepCore

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}

enum Theme {
    static let corner: CGFloat = 20
    static let accent = Color(hex: "E5484D")
    static let offer = Color(hex: "15803D")   // ≥ 4.5:1 with white
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "FF8A5B"), Color(hex: "FF5E9C"), Color(hex: "7C5CFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Recipe {
    var colors: [Color] { gradient.map(Color.init(hex:)) }
    /// The recipe's colour darkened until white text on it reaches 4:1 contrast — used for buttons,
    /// icons and text, while `linearGradient`/photos keep the bright original.
    @MainActor var tint: Color {
        // Of the two gradient colours, take the darker one: it needs the least darkening to stay vivid.
        let hex = gradient.min { ColorContrast.luminance(hex: $0) < ColorContrast.luminance(hex: $1) } ?? "E5484D"
        if let cached = ReadableTints.cache[hex] { return cached }
        let color = Color(hex: ColorContrast.readableBackground(for: ReadableTints.amberized(hex), textHex: "FFFFFF",
                                                                minimum: 4.0))
        ReadableTints.cache[hex] = color
        return color
    }
    var linearGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

@MainActor
private enum ReadableTints {
    static var cache: [String: Color] = [:]

    /// Yellows turn olive when darkened; nudge them toward amber first so the result stays warm.
    static func amberized(_ hex: String) -> String {
        let value = UInt64(hex, radix: 16) ?? 0
        let color = UIColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                            blue: CGFloat(value & 0xFF) / 255, alpha: 1)
        var h: CGFloat = 0, sat: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &sat, brightness: &b, alpha: &a)
        guard (40.0 / 360...75.0 / 360).contains(h) else { return hex }
        var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0
        UIColor(hue: 30.0 / 360, saturation: max(sat, 0.8), brightness: b, alpha: 1).getRed(&r, green: &g, blue: &bl, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(bl * 255))
    }
}

extension Chain {
    var color: Color { Color(hex: brandHex) }
    /// Black or white, whichever reads better on the brand colour (Netto yellow, Bilka light blue → black).
    var onColor: Color { ColorContrast.prefersDarkText(onHex: brandHex) ? .black : .white }
}

extension Font {
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension Double {
    func kr(_ fractionDigits: Int = 0) -> String {
        "\(formatted(.number.precision(.fractionLength(fractionDigits)))) kr"
    }
}

func formatDistance(_ meters: Double) -> String {
    meters < 1000 ? "\(Int((meters / 10).rounded() * 10)) m" : String(format: "%.1f km", meters / 1000)
}
