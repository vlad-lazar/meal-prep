import Foundation

public enum AmountFormatter {
    /// Human-friendly amount: g/ml rounded to 5 above 50, promoted to kg/l from 1000;
    /// pieces and spoons rounded up to the nearest half (minimum 0.5).
    public static func format(_ amount: Double, _ unit: MeasureUnit) -> String {
        switch unit {
        case .g, .kg:
            return metric(amount * unit.baseFactor, small: "g", large: "kg")
        case .ml, .cl, .l:
            return metric(amount * unit.baseFactor, small: "ml", large: "l")
        case .pcs, .tbsp, .tsp:
            let halves = max(0.5, (amount * 2).rounded(.up) / 2)
            return "\(number(halves)) \(unit.symbol)"
        }
    }

    private static func metric(_ base: Double, small: String, large: String) -> String {
        if base >= 1000 {
            return "\(number((base / 100).rounded() / 10)) \(large)"
        }
        let rounded = base >= 50 ? (base / 5).rounded() * 5 : base.rounded()
        return "\(Int(rounded)) \(small)"
    }

    private static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
