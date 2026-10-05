import SwiftUI
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
    static let accent = Color(hex: "FF5E62")
    static let offer = Color(hex: "16A34A")
    static let brandGradient = LinearGradient(
        colors: [Color(hex: "FF8A5B"), Color(hex: "FF5E9C"), Color(hex: "7C5CFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Recipe {
    var colors: [Color] { gradient.map(Color.init(hex:)) }
    var tint: Color { colors.first ?? Theme.accent }
    var linearGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Chain {
    var color: Color { Color(hex: brandHex) }
    /// Netto's yellow needs dark text.
    var onColor: Color { self == .netto ? .black : .white }
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
