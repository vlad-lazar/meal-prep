import SwiftUI
import MealPrepCore

struct PrepDoneView: View {
    let recipe: Recipe
    let basket: Basket
    let gramsPerPortion: Double
    let onClose: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    RecipePhoto(recipe: recipe, emojiSize: 80)
                        .frame(width: 180, height: 180)
                        .clipShape(.circle)
                        .overlay(alignment: .bottomTrailing) {
                            Text("🎉").font(.system(size: 54)).offset(x: 10, y: 6)
                        }
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(duration: 0.6, bounce: 0.6), value: appeared)
                    Text("Prep done!").font(.rounded(.largeTitle))
                    Text("Split into \(basket.portions) containers — about \(Int((gramsPerPortion / 10).rounded() * 10)) g of ingredients each.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    GlassEffectContainer(spacing: 10) {
                        HStack(spacing: 10) {
                            StatPill(systemImage: "cart", text: basket.shoppingTotal.kr(), tint: recipe.tint)
                            StatPill(systemImage: "banknote", text: "\(basket.costPerPortion.kr()) / portion", tint: recipe.tint)
                        }
                    }
                    Label {
                        Text(recipe.storageTip)
                    } icon: {
                        Image(systemName: "refrigerator").foregroundStyle(recipe.tint)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardBackground()
                    Button(action: onClose) {
                        Text("Done").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(recipe.tint)
                    .controlSize(.large)
                }
                .padding(24)
                .padding(.top, 40)
            }
            ConfettiView(colors: recipe.colors + [.yellow, .pink, .mint])
                .ignoresSafeArea()
        }
        .onAppear { appeared = true }
    }
}
