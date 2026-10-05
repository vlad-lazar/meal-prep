import Foundation

public enum CatalogError: Error, Equatable {
    case missingResource(String)
}

public struct Catalog: Sendable {
    public let recipes: [Recipe]
    public let ingredientList: [Ingredient]
    public let nutritionList: [NutritionEntry]
    public let ingredients: [String: Ingredient]
    public let nutrition: [String: NutritionFacts]

    public init(recipes: [Recipe], ingredients: [Ingredient], nutrition: [NutritionEntry]) {
        self.recipes = recipes
        self.ingredientList = ingredients
        self.nutritionList = nutrition
        self.ingredients = Dictionary(ingredients.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.nutrition = Dictionary(nutrition.map { ($0.id, $0.per100g) }, uniquingKeysWith: { first, _ in first })
    }

    public static func decode(recipes: Data, ingredients: Data, nutrition: Data) throws -> Catalog {
        let decoder = JSONDecoder()
        return Catalog(
            recipes: try decoder.decode([Recipe].self, from: recipes),
            ingredients: try decoder.decode([Ingredient].self, from: ingredients),
            nutrition: try decoder.decode([NutritionEntry].self, from: nutrition)
        )
    }

    public func ingredient(_ id: String) -> Ingredient? { ingredients[id] }
    public func recipe(_ id: String) -> Recipe? { recipes.first { $0.id == id } }
    public var cuisines: [String] { Array(Set(recipes.map(\.cuisine))).sorted() }
}
