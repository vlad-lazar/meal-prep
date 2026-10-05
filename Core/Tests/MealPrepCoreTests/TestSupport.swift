import Foundation
@testable import MealPrepCore

func approx(_ a: Double?, _ b: Double, tolerance: Double = 1e-6) -> Bool {
    guard let a else { return false }
    return abs(a - b) <= tolerance
}

enum Fixtures {
    static let chicken = Ingredient(
        id: "chicken-breast", name: "Chicken breast", danishName: "Kyllingebrystfilet",
        searchTerms: ["kyllingebryst"], excludeTerms: ["pålæg", "marineret"], section: .meat, isPantry: false,
        typicalPack: Pack(amount: 500, unit: .g, priceDKK: 45), gramsPerPiece: nil, mlDensity: nil,
        nutritionId: "chicken-breast")
    static let rice = Ingredient(
        id: "rice", name: "Jasmine rice", danishName: "Jasminris",
        searchTerms: ["jasminris", "ris"], excludeTerms: ["risengrød"], section: .dry, isPantry: false,
        typicalPack: Pack(amount: 1000, unit: .g, priceDKK: 18), gramsPerPiece: nil, mlDensity: nil,
        nutritionId: "rice")
    static let oil = Ingredient(
        id: "rapeseed-oil", name: "Rapeseed oil", danishName: "Rapsolie",
        searchTerms: ["rapsolie"], excludeTerms: [], section: .spices, isPantry: true,
        typicalPack: Pack(amount: 1000, unit: .ml, priceDKK: 25), gramsPerPiece: nil, mlDensity: 0.92,
        nutritionId: "rapeseed-oil")
    static let onion = Ingredient(
        id: "onion", name: "Onion", danishName: "Løg",
        searchTerms: ["løg"], excludeTerms: ["rødløg"], section: .produce, isPantry: false,
        typicalPack: Pack(amount: 1000, unit: .g, priceDKK: 8), gramsPerPiece: 150, mlDensity: nil,
        nutritionId: "onion")

    static let curry = Recipe(
        id: "curry", name: "Chicken curry", cuisine: "Indian", emoji: "🍛", gradient: ["FFB347", "FF6B6B"],
        minutes: 40, difficulty: .easy, basePortions: 4,
        ingredients: [
            RecipeIngredient(ingredientId: "chicken-breast", amount: 600, unit: .g, note: nil),
            RecipeIngredient(ingredientId: "rice", amount: 400, unit: .g, note: nil),
            RecipeIngredient(ingredientId: "onion", amount: 2, unit: .pcs, note: nil),
            RecipeIngredient(ingredientId: "rapeseed-oil", amount: 2, unit: .tbsp, note: nil),
        ],
        steps: [Step(text: "Cook.", timerSeconds: nil)], storageTip: "Fridge 4 days.")

    static let catalog = Catalog(
        recipes: [curry],
        ingredients: [chicken, rice, oil, onion],
        nutrition: [
            NutritionEntry(id: "chicken-breast", name: "Kylling", fridaId: nil,
                           per100g: NutritionFacts(kcal: 114, protein: 23, carbs: 0, fat: 2, fibre: 0)),
            NutritionEntry(id: "rice", name: "Ris", fridaId: nil,
                           per100g: NutritionFacts(kcal: 350, protein: 7, carbs: 78, fat: 1, fibre: 1)),
            NutritionEntry(id: "rapeseed-oil", name: "Rapsolie", fridaId: nil,
                           per100g: NutritionFacts(kcal: 900, protein: 0, carbs: 0, fat: 100, fibre: 0)),
            NutritionEntry(id: "onion", name: "Løg", fridaId: nil,
                           per100g: NutritionFacts(kcal: 40, protein: 1, carbs: 8, fat: 0, fibre: 2)),
        ])
}
