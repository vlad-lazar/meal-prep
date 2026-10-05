import SwiftUI

struct PrepView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            if let prep = model.activePrep, let recipe = model.catalog.recipe(prep.recipeId) {
                ShoppingListView(prep: prep, recipe: recipe)
            } else {
                ContentUnavailableView {
                    Label("No prep yet", systemImage: "cart")
                } description: {
                    Text("Pick a meal and a store to get your shopping list.")
                } actions: {
                    Button("Browse meals") { model.selectedTab = .meals }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.accent)
                }
                .background { AppBackground() }
                .navigationTitle("Prep")
            }
        }
    }
}
