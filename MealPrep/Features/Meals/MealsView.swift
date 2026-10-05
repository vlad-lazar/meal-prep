import SwiftUI
import MealPrepCore

struct MealsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List(model.catalog.recipes) { recipe in
                HStack {
                    Text(recipe.emoji)
                    Text(recipe.name)
                    Spacer()
                    PriceText(value: model.quotes[recipe.id]?.costPerPortion ?? 0)
                }
            }
            .navigationTitle(model.locationLabel)
        }
    }
}
