import SwiftUI
import SwiftData

@main
struct MealPrepApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
        .modelContainer(for: [PrepSession.self, FavouriteRecipe.self])
    }
}
