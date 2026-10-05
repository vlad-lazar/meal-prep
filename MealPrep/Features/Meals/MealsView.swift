import SwiftUI
import SwiftData
import MealPrepCore

struct MealsView: View {
    @Environment(AppModel.self) private var model
    @Query private var favourites: [FavouriteRecipe]
    @State private var filter = MealFilter()
    @State private var path: [MealRoute] = []
    @State private var showPostcode = false
    @Namespace private var zoom

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var results: [Recipe] { filter.apply(model.catalog.recipes, quotes: model.quotes) }
    private var cheap: [Recipe] { MealFilter.cheapThisWeek(model.catalog.recipes, quotes: model.quotes) }
    private var favouriteIds: Set<String> { Set(favourites.map(\.recipeId)) }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if model.locationState == .needsPostcode {
                        Button { showPostcode = true } label: {
                            BannerView(text: "Set your area to compare nearby stores.", systemImage: "location.slash")
                        }
                        .buttonStyle(.plain)
                    } else if let banner = model.offersBanner {
                        BannerView(text: banner)
                    }
                    FilterBar(filter: $filter, cuisines: model.catalog.cuisines)
                    if !filter.isActive && !cheap.isEmpty {
                        cheapCarousel
                    }
                    SectionTitle(text: filter.isActive ? "\(results.count) meals" : "All meals")
                        .contentTransition(.numericText())
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(results) { recipe in
                            card(recipe, sourceID: recipe.id)
                        }
                    }
                    if results.isEmpty {
                        ContentUnavailableView("No meals match", systemImage: "fork.knife",
                                               description: Text("Try loosening a filter."))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .animation(.snappy, value: filter)
            }
            .scrollIndicators(.hidden)
            .background { AppBackground() }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { locationButton }
            }
            .searchable(text: $filter.query, prompt: "Search meals or cuisines")
            .refreshable { await model.refreshNearby() }
            .navigationDestination(for: MealRoute.self) { route in
                if let recipe = model.catalog.recipe(route.recipeId) {
                    MealDetailView(recipe: recipe, portions: route.portions)
                        .navigationTransition(.zoom(sourceID: route.sourceID ?? route.recipeId, in: zoom))
                }
            }
            .sheet(isPresented: $showPostcode) { PostcodeSheet() }
            .onAppear {
                #if DEBUG
                if path.isEmpty, let id = DebugLaunch.openRecipe { path = [MealRoute(recipeId: id)] }
                #endif
            }
        }
    }

    private var locationButton: some View {
        Button { showPostcode = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse, isActive: model.isLoadingOffers)
                Text(model.locationLabel).lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 4)
        }
    }

    private var cheapCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Cheap this week", systemImage: "flame.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(cheap) { recipe in
                        card(recipe, sourceID: "cheap-\(recipe.id)", height: 240, showChain: true)
                            .frame(width: 210)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                    .rotation3DEffect(.degrees(phase.value * -8), axis: (x: 0, y: 1, z: 0))
                            }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollTargetBehavior(.viewAligned)
            .padding(.horizontal, -16)
        }
    }

    private func card(_ recipe: Recipe, sourceID: String, height: CGFloat = 210, showChain: Bool = false) -> some View {
        NavigationLink(value: MealRoute(recipeId: recipe.id, sourceID: sourceID)) {
            MealCard(recipe: recipe, quote: model.quotes[recipe.id], isFavourite: favouriteIds.contains(recipe.id),
                     height: height, showChain: showChain)
                .matchedTransitionSource(id: sourceID, in: zoom)
        }
        .buttonStyle(.plain)
    }
}
