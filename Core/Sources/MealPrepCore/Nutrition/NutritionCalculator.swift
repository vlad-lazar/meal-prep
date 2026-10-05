import Foundation

public struct NutritionCalculator: Sendable {
    public let catalog: Catalog

    public init(catalog: Catalog) {
        self.catalog = catalog
    }

    public func perPortion(_ recipe: Recipe) -> NutritionFacts {
        let total = recipe.ingredients.reduce(NutritionFacts.zero) { sum, item in
            guard let ingredient = catalog.ingredient(item.ingredientId),
                  let per100g = catalog.nutrition[ingredient.nutritionId],
                  let grams = ingredient.converter.grams(item.amount, item.unit) else { return sum }
            return sum + per100g.scaled(by: grams / 100)
        }
        return total.scaled(by: 1 / Double(max(1, recipe.basePortions)))
    }

    public func rawGramsPerPortion(_ recipe: Recipe) -> Double {
        let grams = recipe.ingredients.reduce(0.0) { sum, item in
            guard let ingredient = catalog.ingredient(item.ingredientId), !ingredient.isPantry,
                  let grams = ingredient.converter.grams(item.amount, item.unit) else { return sum }
            return sum + grams
        }
        return grams / Double(max(1, recipe.basePortions))
    }
}
