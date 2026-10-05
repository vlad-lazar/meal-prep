import Testing
@testable import MealPrepCore

struct AmountFormatterTests {
    @Test func grams() {
        #expect(AmountFormatter.format(600, .g) == "600 g")
        #expect(AmountFormatter.format(603, .g) == "605 g")
        #expect(AmountFormatter.format(12, .g) == "12 g")
        #expect(AmountFormatter.format(1500, .g) == "1.5 kg")
        #expect(AmountFormatter.format(2000, .g) == "2 kg")
    }

    @Test func volumes() {
        #expect(AmountFormatter.format(400, .ml) == "400 ml")
        #expect(AmountFormatter.format(1250, .ml) == "1.3 l")
        #expect(AmountFormatter.format(1, .l) == "1 l")
    }

    @Test func countsRoundToHalves() {
        #expect(AmountFormatter.format(1.25, .pcs) == "1.5 stk")
        #expect(AmountFormatter.format(2, .pcs) == "2 stk")
        #expect(AmountFormatter.format(0.1, .tsp) == "0.5 tsk")
        #expect(AmountFormatter.format(3, .tbsp) == "3 spsk")
    }
}
