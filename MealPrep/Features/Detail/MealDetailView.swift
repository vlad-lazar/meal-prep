import SwiftUI
import SwiftData
import MealPrepCore

struct MealDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query private var favourites: [FavouriteRecipe]
    let recipe: Recipe
    @State private var portions: Int
    @State private var showStores = false

    init(recipe: Recipe, portions: Int? = nil) {
        self.recipe = recipe
        _portions = State(initialValue: min(12, max(2, portions ?? recipe.basePortions)))
    }

    private var isFavourite: Bool { favourites.contains { $0.recipeId == recipe.id } }
    private var baskets: [Basket] { model.baskets(for: recipe, portions: portions) }
    /// Cheapest total shop (what the stepper hint shows) …
    private var bestBasket: Basket { baskets[0] }
    /// … and cheapest cost per portion (matches the price on the meal card).
    private var cheapestPerPortion: Double { baskets.map(\.costPerPortion).min() ?? 0 }
    private var scale: Double { Double(portions) / Double(max(1, recipe.basePortions)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(alignment: .leading, spacing: 24) {
                    if let credit = PhotoCredits.text(for: recipe.id) {
                        Text(credit).font(.caption2).foregroundStyle(.secondary).padding(.top, -14)
                    }
                    stats
                    if let video = recipe.video {
                        RecipeVideoCard(video: video, tint: recipe.tint)
                    }
                    portionStepper
                    ingredients
                    NutritionCard(facts: model.nutrition.perPortion(recipe), tint: recipe.tint)
                    steps
                    storage
                }
                .padding(16)
                .padding(.bottom, 90)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background { AppBackground() }
        .safeAreaInset(edge: .bottom) { findStoresButton }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleFavourite) {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavourite ? Color.pink : Color.primary)
                        .symbolEffect(.bounce, value: isFavourite)
                }
            }
        }
        .navigationDestination(isPresented: $showStores) {
            StoreComparisonView(recipe: recipe, portions: portions)
        }
        .onAppear {
            #if DEBUG
            if DebugLaunch.showStores { showStores = true }
            #endif
        }
    }

    private var header: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            ZStack(alignment: .bottomLeading) {
                RecipePhoto(recipe: recipe, emojiSize: 120, targetWidth: 440)
                LinearGradient(colors: [.clear, .clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.cuisine.uppercased())
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .glassEffect(.regular, in: .capsule)
                    Text(recipe.name)
                        .font(.rounded(.largeTitle))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
            }
            .frame(width: geo.size.width, height: 340 + max(0, minY))
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36))
            .offset(y: minY > 0 ? -minY : -minY * 0.35)
        }
        .frame(height: 340)
    }

    private var stats: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                StatPill(systemImage: "banknote", text: "\(cheapestPerPortion.kr())/portion", tint: recipe.tint)
                StatPill(systemImage: "clock", text: "\(recipe.minutes) min", tint: recipe.tint)
                StatPill(systemImage: "flame", text: recipe.difficulty.label, tint: recipe.tint)
            }
        }
    }

    private var portionStepper: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Portions").font(.rounded(.headline))
                Text("≈ \(bestBasket.shoppingTotal.kr()) at \(bestBasket.displayName)")
                    .font(.caption).foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
            }
            Spacer()
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button { change(by: -1) } label: {
                        Image(systemName: "minus").frame(width: 22, height: 22)
                    }
                    .buttonStyle(.glass)
                    .disabled(portions <= 2)
                    Text("\(portions)")
                        .font(.rounded(.title2))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(portions)))
                        .frame(minWidth: 30)
                    Button { change(by: 1) } label: {
                        Image(systemName: "plus").frame(width: 22, height: 22)
                    }
                    .buttonStyle(.glass)
                    .disabled(portions >= 12)
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    private var ingredients: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Ingredients")
            VStack(spacing: 0) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, item in
                    if let ingredient = model.catalog.ingredient(item.ingredientId) {
                        HStack {
                            Text(ingredient.name)
                            if ingredient.isPantry {
                                Text("pantry")
                                    .font(.caption2)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .glassEffect(.regular, in: .capsule)
                            }
                            Spacer()
                            Text(AmountFormatter.format(item.amount * scale, item.unit))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                        .padding(.vertical, 10)
                        if index < recipe.ingredients.count - 1 { Divider() }
                    }
                }
            }
            .padding(.horizontal, 16)
            .cardBackground()
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Steps")
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.rounded(.subheadline))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(recipe.tint, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.text)
                            if let seconds = step.timerSeconds {
                                Label("\(max(1, (seconds + 59) / 60)) min", systemImage: "timer")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .cardBackground()
        }
    }

    private var storage: some View {
        Label {
            Text(recipe.storageTip)
        } icon: {
            Image(systemName: "refrigerator").foregroundStyle(recipe.tint)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var findStoresButton: some View {
        Button { showStores = true } label: {
            Label("Find stores", systemImage: "storefront")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .tint(recipe.tint)
        .controlSize(.large)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func change(by delta: Int) {
        Haptics.selection()
        withAnimation(.snappy) { portions = min(12, max(2, portions + delta)) }
    }

    private func toggleFavourite() {
        Haptics.selection()
        if let existing = favourites.first(where: { $0.recipeId == recipe.id }) {
            context.delete(existing)
        } else {
            context.insert(FavouriteRecipe(recipeId: recipe.id))
        }
        try? context.save()
    }
}
