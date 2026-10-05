import Foundation

/// WCAG contrast helpers on 6-digit hex colours (no SwiftUI dependency, so they're testable).
public enum ColorContrast {
    static func components(_ hex: String) -> (Double, Double, Double) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }

    static func hex(_ r: Double, _ g: Double, _ b: Double) -> String {
        String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    /// WCAG relative luminance (0 = black, 1 = white).
    public static func luminance(hex: String) -> Double {
        func linear(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let (r, g, b) = components(hex)
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    public static func contrast(hex a: String, with b: String) -> Double {
        let la = luminance(hex: a), lb = luminance(hex: b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// Darkens `hex` (keeping its hue) just enough for `textHex` to reach `minimum` contrast on it.
    public static func readableBackground(for hex: String, textHex: String, minimum: Double) -> String {
        if contrast(hex: hex, with: textHex) >= minimum { return hex }
        let (r, g, b) = components(hex)
        var low = 0.0, high = 1.0
        for _ in 0..<20 {
            let mid = (low + high) / 2
            if contrast(hex: Self.hex(r * mid, g * mid, b * mid), with: textHex) >= minimum { low = mid } else { high = mid }
        }
        return Self.hex(r * low, g * low, b * low)
    }

    /// True when black text reads better than white on `hex`.
    public static func prefersDarkText(onHex hex: String) -> Bool {
        contrast(hex: hex, with: "000000") > contrast(hex: hex, with: "FFFFFF")
    }
}
