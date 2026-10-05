import Foundation
import SwiftData

@Model
final class FavouriteRecipe {
    @Attribute(.unique) var recipeId: String
    var addedAt: Date

    init(recipeId: String, addedAt: Date = .now) {
        self.recipeId = recipeId
        self.addedAt = addedAt
    }
}
