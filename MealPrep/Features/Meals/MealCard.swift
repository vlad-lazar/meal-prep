import SwiftUI
import MealPrepCore

struct MealCard: View {
    let recipe: Recipe
    let quote: MealQuote?
    var isFavourite = false
    var height: CGFloat = 210
    /// Carousel cards show the cheapest chain instead of cooking time.
    var showChain = false

    var body: some View {
        ZStack(alignment: .bottom) {
            recipe.linearGradient
            Text(recipe.emoji)
                .font(.system(size: height * 0.3))
                .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, height * 0.3)
            info.padding(8)
        }
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 26))
        .overlay(alignment: .topTrailing) {
            if quote?.hasOffer == true {
                Label("Offer", systemImage: "tag.fill")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .glassEffect(.regular.tint(Theme.offer), in: .capsule)
                    .padding(10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .topLeading) {
            if isFavourite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                    .padding(7)
                    .glassEffect(.regular, in: .circle)
                    .padding(10)
            }
        }
        .shadow(color: recipe.tint.opacity(0.35), radius: 14, y: 8)
        .contentShape(.rect(cornerRadius: 26))
        .animation(.snappy, value: quote?.hasOffer)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipe.name)
                .font(.rounded(.subheadline))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
            HStack(spacing: 6) {
                PriceText(value: quote?.costPerPortion ?? 0)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.primary)
                if showChain, let chain = quote?.chain {
                    Text("at \(chain.displayName)").lineLimit(1)
                } else {
                    Label("\(recipe.minutes)m", systemImage: "clock")
                }
                Spacer(minLength: 0)
                DifficultyDots(difficulty: recipe.difficulty, tint: .primary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
