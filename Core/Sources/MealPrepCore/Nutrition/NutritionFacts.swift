import Foundation

public struct NutritionFacts: Codable, Sendable, Hashable {
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var fibre: Double

    public init(kcal: Double, protein: Double, carbs: Double, fat: Double, fibre: Double) {
        self.kcal = kcal; self.protein = protein; self.carbs = carbs; self.fat = fat; self.fibre = fibre
    }

    public static let zero = NutritionFacts(kcal: 0, protein: 0, carbs: 0, fat: 0, fibre: 0)

    public static func + (a: NutritionFacts, b: NutritionFacts) -> NutritionFacts {
        NutritionFacts(kcal: a.kcal + b.kcal, protein: a.protein + b.protein, carbs: a.carbs + b.carbs,
                       fat: a.fat + b.fat, fibre: a.fibre + b.fibre)
    }

    public func scaled(by factor: Double) -> NutritionFacts {
        NutritionFacts(kcal: kcal * factor, protein: protein * factor, carbs: carbs * factor,
                       fat: fat * factor, fibre: fibre * factor)
    }
}

/// One row of nutrition.json — values per 100 g from the DTU Frida food database.
public struct NutritionEntry: Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let fridaId: Int?
    public let per100g: NutritionFacts
}
