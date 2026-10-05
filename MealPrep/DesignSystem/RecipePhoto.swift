import SwiftUI
import UIKit
import MealPrepCore

/// Decoded, downsized photos keyed by recipe id and pixel width. Decoding full-size JPEGs for every
/// small card was the main scrolling cost.
@MainActor
enum PhotoCache {
    private static let cache = NSCache<NSString, UIImage>()
    private static let missing = NSCache<NSString, NSNumber>()

    static func hasPhoto(_ recipeId: String) -> Bool {
        if missing.object(forKey: recipeId as NSString) != nil { return false }
        if UIImage(named: "photo-\(recipeId)") != nil { return true }
        missing.setObject(1, forKey: recipeId as NSString)
        return false
    }

    static func cached(_ recipeId: String, pixelWidth: Int) -> UIImage? {
        cache.object(forKey: "\(recipeId)@\(pixelWidth)" as NSString)
    }

    static func load(_ recipeId: String, pixelWidth: Int) async -> UIImage? {
        if let hit = cached(recipeId, pixelWidth: pixelWidth) { return hit }
        guard let full = UIImage(named: "photo-\(recipeId)") else { return nil }
        let scale = min(1, CGFloat(pixelWidth) / max(full.size.width, 1))
        let size = CGSize(width: full.size.width * scale, height: full.size.height * scale)
        let thumbnail = await full.byPreparingThumbnail(ofSize: size) ?? full
        cache.setObject(thumbnail, forKey: "\(recipeId)@\(pixelWidth)" as NSString)
        return thumbnail
    }
}

/// The recipe's bundled photo (asset `photo-<id>`), or its gradient + emoji when there is none.
struct RecipePhoto: View {
    let recipe: Recipe
    var emojiSize: CGFloat = 56
    /// Lifts the fallback emoji above an overlaid panel.
    var emojiBottomInset: CGFloat = 0
    /// Rough on-screen width in points; the photo is decoded at 3× this.
    var targetWidth: CGFloat = 220

    @State private var image: UIImage?

    private var pixelWidth: Int { Int(targetWidth * 3) }

    var body: some View {
        if PhotoCache.hasPhoto(recipe.id) {
            Color.clear
                .overlay {
                    if let image = image ?? PhotoCache.cached(recipe.id, pixelWidth: pixelWidth) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        recipe.linearGradient.opacity(0.6)
                    }
                }
                .clipped()
                .task(id: recipe.id) {
                    image = await PhotoCache.load(recipe.id, pixelWidth: pixelWidth)
                }
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
