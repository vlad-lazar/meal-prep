import Testing
@testable import MealPrepCore

struct NutritionCalculatorTests {
    let calculator = NutritionCalculator(catalog: Fixtures.catalog)

    // curry (4 portions): 600 g chicken (114 kcal/23 p/2 f), 400 g rice (350/7 p/78 c/1 f/1 fib),
    // 2 onions = 300 g (40/1 p/8 c/2 fib), 2 tbsp oil = 30 ml × 0.92 = 27.6 g (900 kcal/100 f)
    @Test func perPortionIncludesPantry() {
        let facts = calculator.perPortion(Fixtures.curry)
        #expect(approx(facts.kcal, (684 + 1400 + 120 + 248.4) / 4))
        #expect(approx(facts.protein, (138 + 28 + 3) / 4))
        #expect(approx(facts.carbs, (312 + 24) / 4))
        #expect(approx(facts.fat, (12 + 4 + 27.6) / 4))
        #expect(approx(facts.fibre, (4 + 6) / 4))
    }

    @Test func rawGramsExcludePantry() {
        #expect(approx(calculator.rawGramsPerPortion(Fixtures.curry), (600 + 400 + 300) / 4))
    }

    @Test func missingNutritionIsSkipped() {
        let catalog = Catalog(recipes: [], ingredients: [Fixtures.chicken], nutrition: [])
        #expect(NutritionCalculator(catalog: catalog).perPortion(Fixtures.curry) == .zero)
    }
}
