import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            Tab("Meals", systemImage: "fork.knife", value: AppTab.meals) {
                MealsView()
            }
            Tab("Prep", systemImage: "checklist", value: AppTab.prep) {
                PrepView()
            }
            .badge(model.activePrep?.remainingCount ?? 0)
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView()
            }
        }
        .tint(Theme.accent)
        .task(id: hasOnboarded) {
            if hasOnboarded { await model.start() }
        }
    }
}
