import Testing
@testable import MealPrepCore

struct UnitConverterTests {
    let plain = UnitConverter()

    @Test func massConversions() {
        #expect(approx(plain.convert(1.5, from: .kg, to: .g), 1500))
        #expect(approx(plain.convert(250, from: .g, to: .kg), 0.25))
    }

    @Test func volumeConversions() {
        #expect(approx(plain.convert(2, from: .tbsp, to: .ml), 30))
        #expect(approx(plain.convert(3, from: .tsp, to: .ml), 15))
        #expect(approx(plain.convert(50, from: .cl, to: .l), 0.5))
    }

    @Test func piecesNeedGramsPerPiece() {
        #expect(plain.convert(2, from: .pcs, to: .g) == nil)
        let onion = UnitConverter(gramsPerPiece: 150)
        #expect(approx(onion.convert(2, from: .pcs, to: .g), 300))
        #expect(approx(onion.convert(1, from: .kg, to: .pcs), 1000.0 / 150.0))
    }

    @Test func volumeToMassNeedsDensity() {
        #expect(plain.convert(100, from: .ml, to: .g) == nil)
        let oil = UnitConverter(mlDensity: 0.92)
        #expect(approx(oil.convert(1, from: .tbsp, to: .g), 13.8))
        #expect(approx(oil.grams(1, .l), 920))
    }

    @Test func countToVolumeBridgesThroughGrams() {
        let egg = UnitConverter(gramsPerPiece: 60, mlDensity: 1.0)
        #expect(approx(egg.convert(2, from: .pcs, to: .ml), 120))
        #expect(UnitConverter(gramsPerPiece: 60).convert(1, from: .pcs, to: .ml) == nil)
    }
}
