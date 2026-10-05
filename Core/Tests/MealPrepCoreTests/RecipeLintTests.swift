import Testing
@testable import MealPrepCore

struct RecipeLintTests {
    let catalog: Catalog

    init() throws {
        catalog = try Catalog.bundled()
    }

    @Test func libraryCoversDifficultiesAndCuisines() {
        #expect(catalog.recipes.count >= 40)
        #expect(Set(catalog.recipes.map(\.difficulty)) == Set(Difficulty.allCases))
        #expect(catalog.cuisines.count >= 6)
        #expect(Set(catalog.recipes.map(\.id)).count == catalog.recipes.count)
    }

    @Test func recipeFieldsAreValid() {
        for recipe in catalog.recipes {
            #expect(!recipe.name.isEmpty && !recipe.emoji.isEmpty && !recipe.storageTip.isEmpty, "\(recipe.id)")
            #expect(recipe.gradient.count == 2, "\(recipe.id) gradient")
            for hex in recipe.gradient {
                #expect(hex.count == 6 && UInt64(hex, radix: 16) != nil, "\(recipe.id) bad hex \(hex)")
            }
            #expect((5...240).contains(recipe.minutes), "\(recipe.id) minutes")
            #expect((1...12).contains(recipe.basePortions), "\(recipe.id) portions")
            #expect(recipe.steps.count >= 3, "\(recipe.id) needs at least 3 steps")
            for step in recipe.steps {
                #expect(!step.text.isEmpty, "\(recipe.id) empty step")
                if let seconds = step.timerSeconds {
                    #expect((10...14_400).contains(seconds), "\(recipe.id) timer \(seconds)")
                }
            }
        }
    }

    @Test func stepTokensAreValid() {
        for recipe in catalog.recipes {
            for step in recipe.steps {
                #expect(StepText.invalidTokens(in: step.text).isEmpty, "\(recipe.id): \(step.text)")
            }
        }
    }

    @Test func videosAreShortAndWellFormed() {
        for recipe in catalog.recipes {
            guard let video = recipe.video else { continue }
            #expect(video.id.count == 11 && video.id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" },
                    "\(recipe.id) bad video id \(video.id)")
            #expect((5...120).contains(video.seconds), "\(recipe.id) video is \(video.seconds)s")
            #expect(!video.title.isEmpty, "\(recipe.id) video title")
        }
    }

    @Test func ingredientsResolveAndConvert() {
        for recipe in catalog.recipes {
            let ids = recipe.ingredients.map(\.ingredientId)
            #expect(Set(ids).count == ids.count, "\(recipe.id) lists an ingredient twice")
            for item in recipe.ingredients {
                guard let ingredient = catalog.ingredient(item.ingredientId) else {
                    Issue.record("\(recipe.id): unknown ingredient \(item.ingredientId)")
                    continue
                }
                #expect(item.amount > 0, "\(recipe.id)/\(item.ingredientId) amount")
                #expect(ingredient.converter.convert(item.amount, from: item.unit, to: ingredient.typicalPack.unit) != nil,
                        "\(recipe.id)/\(item.ingredientId): \(item.unit) doesn't convert to \(ingredient.typicalPack.unit)")
                #expect(ingredient.converter.grams(item.amount, item.unit) != nil,
                        "\(recipe.id)/\(item.ingredientId): no gram conversion")
            }
        }
    }

    @Test func typicalCostPerPortionInTargetRange() {
        let pricer = BasketPricer(catalog: catalog)
        for recipe in catalog.recipes {
            let cost = pricer.price(recipe, portions: recipe.basePortions, chain: nil, offers: []).costPerPortion
            #expect((8...60).contains(cost), "\(recipe.id) costs \(cost) kr/portion")
        }
    }

    @Test func kcalPerPortionPlausible() {
        let calculator = NutritionCalculator(catalog: catalog)
        for recipe in catalog.recipes {
            let kcal = calculator.perPortion(recipe).kcal
            #expect((200...1200).contains(kcal), "\(recipe.id) has \(kcal) kcal/portion")
        }
    }

    @Test func everyIngredientIsUsed() {
        let used = Set(catalog.recipes.flatMap { $0.ingredients.map(\.ingredientId) })
        for ingredient in catalog.ingredientList {
            #expect(used.contains(ingredient.id), "\(ingredient.id) is never used — remove it or use it")
        }
    }
}
