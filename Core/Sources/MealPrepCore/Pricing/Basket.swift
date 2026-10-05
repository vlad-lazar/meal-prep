import Foundation

public enum PriceSource: Codable, Sendable, Hashable {
    case offer(Offer)
    case typical
}

public struct PricedLine: Codable, Sendable, Hashable, Identifiable {
    public let ingredient: Ingredient
    public let neededAmount: Double
    public let neededUnit: MeasureUnit
    public let packsToBuy: Int
    /// Amount bought per pack, in `packUnit`.
    public let packAmount: Double
    public let packUnit: MeasureUnit
    public let packPrice: Double
    /// Share of the bought packs the recipe actually uses.
    public let usedCost: Double
    public let source: PriceSource

    public var id: String { ingredient.id }
    public var lineTotal: Double { Double(packsToBuy) * packPrice }
    public var offer: Offer? {
        if case .offer(let offer) = source { return offer }
        return nil
    }
    public var isOffer: Bool { offer != nil }
}

public struct Basket: Codable, Sendable, Hashable, Identifiable {
    public let recipeId: String
    public let portions: Int
    public let chain: Chain?
    public let store: Store?
    public let lines: [PricedLine]
    /// Pantry ingredient ids the user does NOT have at home (so they are bought and counted).
    public var pantryOverrides: Set<String>

    public init(recipeId: String, portions: Int, chain: Chain?, store: Store?, lines: [PricedLine], pantryOverrides: Set<String>) {
        self.recipeId = recipeId; self.portions = portions; self.chain = chain; self.store = store
        self.lines = lines; self.pantryOverrides = pantryOverrides
    }

    public var id: String { store?.id ?? chain?.rawValue ?? "estimate" }
    public var displayName: String { store?.name ?? chain?.displayName ?? "Typical prices" }

    public func counts(_ line: PricedLine) -> Bool {
        !line.ingredient.isPantry || pantryOverrides.contains(line.id)
    }
    public var countedLines: [PricedLine] { lines.filter(counts) }
    public var shoppingTotal: Double { countedLines.reduce(0) { $0 + $1.lineTotal } }
    public var mealCost: Double { countedLines.reduce(0) { $0 + $1.usedCost } }
    public var costPerPortion: Double { portions > 0 ? mealCost / Double(portions) : 0 }
    public var offerCount: Int { countedLines.filter(\.isOffer).count }
    public var estimateCount: Int { countedLines.count - offerCount }
}
