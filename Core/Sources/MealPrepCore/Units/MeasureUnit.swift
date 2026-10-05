import Foundation

public enum MeasureUnit: String, Codable, Sendable, CaseIterable {
    case g, kg, ml, cl, l, pcs, tbsp, tsp

    public enum Family: Sendable { case mass, volume, count }

    public var family: Family {
        switch self {
        case .g, .kg: return .mass
        case .ml, .cl, .l, .tbsp, .tsp: return .volume
        case .pcs: return .count
        }
    }

    /// Multiplier to the family's base unit (g, ml or pcs).
    var baseFactor: Double {
        switch self {
        case .g, .ml, .pcs: return 1
        case .kg, .l: return 1000
        case .cl: return 10
        case .tbsp: return 15
        case .tsp: return 5
        }
    }

    /// Danish display symbol.
    public var symbol: String {
        switch self {
        case .pcs: return "stk"
        case .tbsp: return "spsk"
        case .tsp: return "tsk"
        default: return rawValue
        }
    }
}
