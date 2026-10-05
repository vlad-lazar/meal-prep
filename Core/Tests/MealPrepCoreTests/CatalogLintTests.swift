import Testing
@testable import MealPrepCore

struct CatalogLintTests {
    let catalog: Catalog

    init() throws {
        catalog = try Catalog.bundled()
    }

    @Test func hasIngredients() {
        #expect(catalog.ingredientList.count >= 70)
    }

    @Test func idsAreUnique() {
        #expect(Set(catalog.ingredientList.map(\.id)).count == catalog.ingredientList.count)
        #expect(Set(catalog.nutritionList.map(\.id)).count == catalog.nutritionList.count)
    }

    @Test func everyIngredientHasNutrition() {
        for ingredient in catalog.ingredientList {
            #expect(catalog.nutrition[ingredient.nutritionId] != nil, "\(ingredient.id) has no nutrition entry")
        }
    }

    @Test func typicalPacksAreSane() {
        for ingredient in catalog.ingredientList {
            #expect(ingredient.typicalPack.amount > 0 && ingredient.typicalPack.priceDKK > 0, "\(ingredient.id)")
            #expect(ingredient.converter.grams(1, ingredient.typicalPack.unit) != nil,
                    "\(ingredient.id): typical pack unit needs gramsPerPiece or mlDensity")
        }
    }

    @Test func searchTermsAreLowercase() {
        for ingredient in catalog.ingredientList {
            #expect(!ingredient.searchTerms.isEmpty, "\(ingredient.id) has no search terms")
            for term in ingredient.searchTerms + ingredient.excludeTerms {
                #expect(term == OfferMatcher.normalize(term) && !term.isEmpty, "\(ingredient.id): '\(term)'")
            }
        }
    }

    @Test func nutritionIsPlausible() {
        for entry in catalog.nutritionList {
            let facts = entry.per100g
            #expect((0...900).contains(facts.kcal), "\(entry.id) kcal")
            #expect(facts.protein + facts.carbs + facts.fat <= 100.5, "\(entry.id) macros exceed 100 g")
            #expect(facts.protein >= 0 && facts.carbs >= 0 && facts.fat >= 0 && facts.fibre >= 0, "\(entry.id)")
        }
    }
}
