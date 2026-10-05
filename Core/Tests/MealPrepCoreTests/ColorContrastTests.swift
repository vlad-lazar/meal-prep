import Testing
@testable import MealPrepCore

struct ColorContrastTests {
    @Test func luminanceOfBlackAndWhite() {
        #expect(approx(ColorContrast.luminance(hex: "000000"), 0))
        #expect(approx(ColorContrast.luminance(hex: "FFFFFF"), 1))
        #expect(approx(ColorContrast.contrast(hex: "000000", with: "FFFFFF"), 21))
    }

    @Test func yellowsAreDarkenedUntilWhiteTextIsReadable() {
        for hex in ["F2C94C", "FDEB71", "FFE259", "FDC830", "A1C4FD", "FFD950"] {
            let dark = ColorContrast.readableBackground(for: hex, textHex: "FFFFFF", minimum: 4.0)
            #expect(ColorContrast.contrast(hex: dark, with: "FFFFFF") >= 4.0, "\(hex) → \(dark)")
            #expect(dark.count == 6)
        }
    }

    @Test func alreadyDarkColoursAreUnchanged() {
        #expect(ColorContrast.readableBackground(for: "1D2F54", textHex: "FFFFFF", minimum: 4.0) == "1D2F54")
    }

    @Test func picksBlackOrWhiteText() {
        #expect(ColorContrast.prefersDarkText(onHex: "FFD950"))   // Netto yellow
        #expect(ColorContrast.prefersDarkText(onHex: "00AEEF"))   // Bilka light blue
        #expect(!ColorContrast.prefersDarkText(onHex: "014693"))  // REMA blue
        #expect(!ColorContrast.prefersDarkText(onHex: "C31414"))  // Coop red
    }
}
