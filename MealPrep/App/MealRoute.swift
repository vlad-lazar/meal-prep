import Foundation

enum AppTab: Hashable {
    case meals, prep, history
}

/// Navigation value for a meal detail screen. `sourceID` identifies the card the zoom transition starts from.
struct MealRoute: Hashable {
    let recipeId: String
    var portions: Int?
    var sourceID: String?
}
