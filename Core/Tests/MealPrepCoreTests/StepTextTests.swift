import Testing
@testable import MealPrepCore

struct StepTextTests {
    @Test func scalesVolumes() {
        let text = "Cook the rice in {600 ml} water with a lid on."
        #expect(StepText.render(text, scale: 1, portions: 4) == "Cook the rice in 600 ml water with a lid on.")
        #expect(StepText.render(text, scale: 3, portions: 12) == "Cook the rice in 1.8 l water with a lid on.")
        #expect(StepText.render(text, scale: 0.5, portions: 2) == "Cook the rice in 300 ml water with a lid on.")
        #expect(StepText.render("Bring {1.2 l} salted water to the boil", scale: 2, portions: 8)
                == "Bring 2.4 l salted water to the boil")
    }

    @Test func scalesCountsAndPortions() {
        #expect(StepText.render("Shape {12} frikadeller", scale: 0.5, portions: 2) == "Shape 6 frikadeller")
        #expect(StepText.render("Roll about {25} meatballs", scale: 0.5, portions: 2) == "Roll about 13 meatballs")
        #expect(StepText.render("Make {8} hollows", scale: 0.1, portions: 1) == "Make 1 hollows")
        #expect(StepText.render("Divide between {portions} containers", scale: 2.5, portions: 10)
                == "Divide between 10 containers")
    }

    @Test func leavesPlainAndMalformedTextAlone() {
        #expect(StepText.render("Heat the oven to 200 °C.", scale: 3, portions: 12) == "Heat the oven to 200 °C.")
        #expect(StepText.render("Odd {token} here", scale: 2, portions: 8) == "Odd {token} here")
        #expect(StepText.invalidTokens(in: "Odd {token} and {600 ml} and {3 cups}") == ["token", "3 cups"])
    }
}
