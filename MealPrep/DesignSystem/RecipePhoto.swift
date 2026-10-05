import SwiftUI
import UIKit
import MealPrepCore

/// The recipe's bundled photo (asset `photo-<id>`), or its gradient + emoji when there is none.
struct RecipePhoto: View {
    let recipe: Recipe
    var emojiSize: CGFloat = 56
    /// Lifts the fallback emoji above an overlaid panel.
    var emojiBottomInset: CGFloat = 0

    var body: some View {
        if let image = UIImage(named: "photo-\(recipe.id)") {
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
        } else {
            ZStack {
                recipe.linearGradient
                Text(recipe.emoji)
                    .font(.system(size: emojiSize))
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
                    .padding(.bottom, emojiBottomInset)
            }
        }
    }
}

struct PhotoCredit: Decodable {
    let creator: String
    let license: String
    let page: String
}

enum PhotoCredits {
    /// Bundled `photo-credits.json`, keyed by recipe id.
    static let all: [String: PhotoCredit] = {
        guard let url = Bundle.main.url(forResource: "photo-credits", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: PhotoCredit].self, from: data)) ?? [:]
    }()

    static func text(for recipeId: String) -> String? {
        guard let credit = all[recipeId] else { return nil }
        if credit.license == credit.creator { return "Photo: \(credit.creator)" }
        let licence = credit.license.hasPrefix("BY") ? "CC \(credit.license)"
            : (credit.license.hasPrefix("PDM") || credit.license.hasPrefix("CC0")) ? "public domain" : credit.license
        let who = credit.creator.isEmpty ? "" : " by \(credit.creator)"
        return "Photo\(who) · \(licence)"
    }
}
