import Foundation

public enum Difficulty: Int, Codable, Sendable, CaseIterable, Comparable, Identifiable {
    case easy = 1, medium, hard

    public var id: Int { rawValue }
    public var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    public static func < (a: Difficulty, b: Difficulty) -> Bool { a.rawValue < b.rawValue }
}

public enum ShopSection: String, Codable, Sendable, CaseIterable {
    case produce, meat, fish, dairy, bakery, dry, frozen, spices

    public var title: String {
        switch self {
        case .produce: return "Fruit & veg"
        case .meat: return "Meat"
        case .fish: return "Fish"
        case .dairy: return "Dairy & eggs"
        case .bakery: return "Bakery"
        case .dry: return "Dry goods"
        case .frozen: return "Frozen"
        case .spices: return "Oils & spices"
        }
    }
    public var sortIndex: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

public struct Pack: Codable, Sendable, Hashable {
    public let amount: Double
    public let unit: MeasureUnit
    public let priceDKK: Double
    /// DKK per one `unit`.
    public var unitPrice: Double { priceDKK / amount }
}

public struct Ingredient: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let danishName: String
    public let searchTerms: [String]
    public let excludeTerms: [String]
    public let section: ShopSection
    public let isPantry: Bool
    public let typicalPack: Pack
    public let gramsPerPiece: Double?
    public let mlDensity: Double?
    public let nutritionId: String

    public var converter: UnitConverter { UnitConverter(gramsPerPiece: gramsPerPiece, mlDensity: mlDensity) }
    /// DKK per one `typicalPack.unit`.
    public var typicalUnitPrice: Double { typicalPack.unitPrice }
}

public struct RecipeIngredient: Codable, Sendable, Hashable {
    public let ingredientId: String
    public let amount: Double
    public let unit: MeasureUnit
    public let note: String?
}

public struct Step: Codable, Sendable, Hashable {
    public let text: String
    public let timerSeconds: Int?
}

/// A short (≤ 2 min) YouTube video showing the dish being made.
public struct RecipeVideo: Codable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let author: String
    public let seconds: Int

    public var watchURL: URL { URL(string: "https://www.youtube.com/shorts/\(id)")! }
    public var thumbnailURL: URL { URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")! }
}

public struct Recipe: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let cuisine: String
    public let emoji: String
    public let gradient: [String]
    public let minutes: Int
    public let difficulty: Difficulty
    public let basePortions: Int
    public let ingredients: [RecipeIngredient]
    public let steps: [Step]
    public let storageTip: String
    public var video: RecipeVideo? = nil
}
