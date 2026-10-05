import Foundation

/// Step text with scalable placeholders, so amounts in instructions follow the chosen portions:
/// `{600 ml}` → scaled amount, `{12}` → scaled count (min 1), `{portions}` → the portion count.
public enum StepText {
    public static func render(_ text: String, scale: Double, portions: Int) -> String {
        var output = ""
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{"), let close = rest[open...].firstIndex(of: "}") {
            output += rest[..<open]
            let token = String(rest[rest.index(after: open)..<close])
            output += render(token: token, scale: scale, portions: portions) ?? "{\(token)}"
            rest = rest[rest.index(after: close)...]
        }
        return output + rest
    }

    /// Placeholders in `text` that `render` can't interpret (used by the recipe lint).
    public static func invalidTokens(in text: String) -> [String] {
        var invalid: [String] = []
        var rest = Substring(text)
        while let open = rest.firstIndex(of: "{"), let close = rest[open...].firstIndex(of: "}") {
            let token = String(rest[rest.index(after: open)..<close])
            if render(token: token, scale: 1, portions: 1) == nil { invalid.append(token) }
            rest = rest[rest.index(after: close)...]
        }
        return invalid
    }

    static func render(token: String, scale: Double, portions: Int) -> String? {
        if token == "portions" { return String(portions) }
        let parts = token.split(separator: " ")
        guard let first = parts.first, let value = Double(first) else { return nil }
        if parts.count == 1 { return String(max(1, Int((value * scale).rounded()))) }
        guard parts.count == 2, let unit = MeasureUnit(rawValue: String(parts[1])) else { return nil }
        return AmountFormatter.format(value * scale, unit)
    }
}
