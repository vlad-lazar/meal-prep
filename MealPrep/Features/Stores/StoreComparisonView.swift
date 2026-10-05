import SwiftUI
import MealPrepCore

struct StoreComparisonView: View {
    @Environment(AppModel.self) private var model
    let recipe: Recipe
    let portions: Int
    @State private var expanded: String?
    @State private var pendingBasket: Basket?

    private var baskets: [Basket] { model.baskets(for: recipe, portions: portions) }
    private var isLoading: Bool { model.isLoadingOffers && !model.hasLoadedOffers }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                if let banner = model.offersBanner {
                    BannerView(text: banner)
                }
                SectionTitle(text: isLoading ? "Checking this week's offers…" : "Cheapest first")
                    .padding(.top, 4)
                if isLoading {
                    ForEach(0..<4, id: \.self) { _ in StoreRowSkeleton() }
                } else {
                    ForEach(Array(baskets.enumerated()), id: \.element.id) { index, basket in
                        StoreRow(basket: basket,
                                 isBest: index == 0 && baskets.count > 1,
                                 isExpanded: expanded == basket.id,
                                 onToggle: { withAnimation(.snappy) { expanded = expanded == basket.id ? nil : basket.id } },
                                 onUse: { use(basket) })
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background { AppBackground() }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Where to shop")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.refreshNearby() }
        .onAppear { if expanded == nil { expanded = baskets.first?.id } }
        .confirmationDialog("Replace your current shopping list?",
                            isPresented: Binding(get: { pendingBasket != nil }, set: { if !$0 { pendingBasket = nil } }),
                            titleVisibility: .visible) {
            Button("Replace list", role: .destructive) {
                if let basket = pendingBasket { model.startPrep(with: basket) }
            }
        } message: {
            Text("You already have a prep in progress.")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            RecipePhoto(recipe: recipe, emojiSize: 34)
                .frame(width: 60, height: 60)
                .clipShape(.rect(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name).font(.rounded(.headline))
                Text("\(portions) portions · \(model.locationLabel)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .cardBackground(cornerRadius: 26)
    }

    private func use(_ basket: Basket) {
        Haptics.success()
        if model.activePrep != nil {
            pendingBasket = basket
        } else {
            model.startPrep(with: basket)
        }
    }
}
