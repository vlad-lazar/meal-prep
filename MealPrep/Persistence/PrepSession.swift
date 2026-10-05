import Foundation
import SwiftData

@Model
final class PrepSession {
    var id: UUID = UUID()
    var date: Date = Date.now
    var recipeId: String = ""
    var recipeName: String = ""
    var emoji: String = ""
    var portions: Int = 0
    var storeName: String = ""
    var chainRaw: String?
    var shoppingTotal: Double = 0
    var costPerPortion: Double = 0

    init(recipeId: String, recipeName: String, emoji: String, portions: Int, storeName: String,
         chainRaw: String?, shoppingTotal: Double, costPerPortion: Double, date: Date = .now) {
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.emoji = emoji
        self.portions = portions
        self.storeName = storeName
        self.chainRaw = chainRaw
        self.shoppingTotal = shoppingTotal
        self.costPerPortion = costPerPortion
        self.date = date
    }
}
