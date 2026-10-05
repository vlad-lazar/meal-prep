import Foundation
import Testing
@testable import MealPrepCore

struct CatalogTests {
    let ingredientsJSON = """
    [{"id":"chicken-breast","name":"Chicken breast","danishName":"Kyllingebrystfilet",
      "searchTerms":["kyllingebryst"],"excludeTerms":["pålæg"],"section":"meat","isPantry":false,
      "typicalPack":{"amount":500,"unit":"g","priceDKK":45},"nutritionId":"chicken-breast"}]
    """
    let nutritionJSON = """
    [{"id":"chicken-breast","name":"Kylling, bryst, rå","fridaId":1234,
      "per100g":{"kcal":114,"protein":23.1,"carbs":0,"fat":1.9,"fibre":0}}]
    """
    let recipesJSON = """
    [{"id":"test-curry","name":"Test curry","cuisine":"Indian","emoji":"🍛","gradient":["FFB347","FF6B6B"],
      "minutes":40,"difficulty":1,"basePortions":4,
      "ingredients":[{"ingredientId":"chicken-breast","amount":600,"unit":"g"}],
      "steps":[{"text":"Cook it."},{"text":"Simmer.","timerSeconds":900}],
      "storageTip":"Keeps 4 days in the fridge."}]
    """

    @Test func decodesAllThreeFiles() throws {
        let catalog = try Catalog.decode(
            recipes: Data(recipesJSON.utf8),
            ingredients: Data(ingredientsJSON.utf8),
            nutrition: Data(nutritionJSON.utf8)
        )
        let recipe = try #require(catalog.recipe("test-curry"))
        #expect(recipe.difficulty == .easy)
        #expect(recipe.steps[1].timerSeconds == 900)
        #expect(recipe.ingredients[0].note == nil)
        let chicken = try #require(catalog.ingredient("chicken-breast"))
        #expect(chicken.section == .meat)
        #expect(chicken.typicalUnitPrice == 0.09)
        #expect(catalog.nutrition["chicken-breast"]?.protein == 23.1)
        #expect(catalog.cuisines == ["Indian"])
    }

    @Test func decodesOptionalVideo() throws {
        let json = """
        {"id":"v","name":"V","cuisine":"X","emoji":"🍲","gradient":["000000","FFFFFF"],"minutes":10,"difficulty":1,
         "basePortions":2,"ingredients":[],"steps":[],"storageTip":"",
         "video":{"id":"5wiwMKhvuDA","title":"Chili con carne #shorts","author":"Cook","seconds":58}}
        """
        let recipe = try JSONDecoder().decode(Recipe.self, from: Data(json.utf8))
        #expect(recipe.video?.id == "5wiwMKhvuDA")
        #expect(recipe.video?.seconds == 58)
        #expect(recipe.video?.watchURL.absoluteString == "https://www.youtube.com/shorts/5wiwMKhvuDA")
        #expect(recipe.video?.thumbnailURL.absoluteString == "https://i.ytimg.com/vi/5wiwMKhvuDA/hqdefault.jpg")
        #expect(Fixtures.curry.video == nil)
    }

    @Test func nutritionArithmetic() {
        let a = NutritionFacts(kcal: 100, protein: 10, carbs: 5, fat: 2, fibre: 1)
        let sum = a + a.scaled(by: 0.5)
        #expect(sum == NutritionFacts(kcal: 150, protein: 15, carbs: 7.5, fat: 3, fibre: 1.5))
    }

    @Test func difficultyAndSectionOrdering() {
        #expect(Difficulty.easy < Difficulty.hard)
        #expect(Difficulty.medium.label == "Medium")
        #expect(ShopSection.produce.sortIndex < ShopSection.spices.sortIndex)
        #expect(ShopSection.dry.title == "Dry goods")
    }
}
