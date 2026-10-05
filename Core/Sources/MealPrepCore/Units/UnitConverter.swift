import Foundation

/// Converts amounts between units. Crossing families (count/volume ↔ mass) needs the
/// ingredient's grams-per-piece or density; without them the conversion returns nil.
public struct UnitConverter: Sendable, Hashable {
    public var gramsPerPiece: Double?
    public var mlDensity: Double?

    public init(gramsPerPiece: Double? = nil, mlDensity: Double? = nil) {
        self.gramsPerPiece = gramsPerPiece
        self.mlDensity = mlDensity
    }

    public func convert(_ amount: Double, from: MeasureUnit, to: MeasureUnit) -> Double? {
        let base = amount * from.baseFactor
        guard let bridged = bridge(base, from: from.family, to: to.family) else { return nil }
        return bridged / to.baseFactor
    }

    public func grams(_ amount: Double, _ unit: MeasureUnit) -> Double? {
        convert(amount, from: unit, to: .g)
    }

    private func bridge(_ value: Double, from: MeasureUnit.Family, to: MeasureUnit.Family) -> Double? {
        if from == to { return value }
        guard let grams = toGrams(value, from) else { return nil }
        return fromGrams(grams, to)
    }

    private func toGrams(_ value: Double, _ family: MeasureUnit.Family) -> Double? {
        switch family {
        case .mass: return value
        case .volume: return mlDensity.map { value * $0 }
        case .count: return gramsPerPiece.map { value * $0 }
        }
    }

    private func fromGrams(_ grams: Double, _ family: MeasureUnit.Family) -> Double? {
        switch family {
        case .mass: return grams
        case .volume: return mlDensity.flatMap { $0 > 0 ? grams / $0 : nil }
        case .count: return gramsPerPiece.flatMap { $0 > 0 ? grams / $0 : nil }
        }
    }
}
