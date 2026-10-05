import Foundation

/// The shopping list currently being worked through (one at a time).
public struct ActivePrep: Codable, Sendable, Hashable {
    public var basket: Basket
    public var checked: Set<String>
    public let startedAt: Date

    public init(basket: Basket, startedAt: Date = .now, checked: Set<String> = []) {
        self.basket = basket
        self.startedAt = startedAt
        self.checked = checked
    }

    public var recipeId: String { basket.recipeId }
    public var portions: Int { basket.portions }
    /// Lines that must be bought (pantry items only when the user lacks them).
    public var shoppingLines: [PricedLine] { basket.countedLines }
    public var remainingCount: Int { shoppingLines.filter { !checked.contains($0.id) }.count }
    public var progress: Double {
        shoppingLines.isEmpty ? 1 : Double(shoppingLines.count - remainingCount) / Double(shoppingLines.count)
    }

    public mutating func toggle(_ id: String) {
        if checked.contains(id) { checked.remove(id) } else { checked.insert(id) }
    }

    public mutating func setHaveAtHome(_ id: String, _ haveAtHome: Bool) {
        if haveAtHome {
            basket.pantryOverrides.remove(id)
            checked.remove(id)
        } else {
            basket.pantryOverrides.insert(id)
        }
    }
}
