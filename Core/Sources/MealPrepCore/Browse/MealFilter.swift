import Foundation

public struct MealFilter: Sendable, Hashable {
    public var query = ""
    public var maxCostPerPortion: Double?
    public var maxMinutes: Int?
    public var difficulties: Set<Difficulty> = []
    public var cuisines: Set<String> = []

    public init() {}

    public var isActive: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty || maxCostPerPortion != nil || maxMinutes != nil
            || !difficulties.isEmpty || !cuisines.isEmpty
    }

    public func apply(_ recipes: [Recipe], quotes: [String: MealQuote]) -> [Recipe] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        return recipes.filter { recipe in
            if !needle.isEmpty {
                let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
                guard recipe.name.range(of: needle, options: options) != nil
                    || recipe.cuisine.range(of: needle, options: options) != nil else { return false }
            }
            if let max = maxCostPerPortion, let cost = quotes[recipe.id]?.costPerPortion, cost > max { return false }
            if let max = maxMinutes, recipe.minutes > max { return false }
            if !difficulties.isEmpty, !difficulties.contains(recipe.difficulty) { return false }
            if !cuisines.isEmpty, !cuisines.contains(recipe.cuisine) { return false }
            return true
        }
    }

    /// Recipes with at least one ingredient on offer nearby, cheapest per portion first.
    public static func cheapThisWeek(_ recipes: [Recipe], quotes: [String: MealQuote], limit: Int = 8) -> [Recipe] {
        Array(recipes
            .filter { quotes[$0.id]?.hasOffer == true }
            .sorted { (quotes[$0.id]?.costPerPortion ?? .infinity) < (quotes[$1.id]?.costPerPortion ?? .infinity) }
            .prefix(limit))
    }
}
