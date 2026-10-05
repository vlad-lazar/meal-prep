import SwiftUI
import SwiftData
import MealPrepCore

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: \PrepSession.date, order: .reverse) private var sessions: [PrepSession]
    @Query(sort: \FavouriteRecipe.addedAt, order: .reverse) private var favourites: [FavouriteRecipe]

    private var monthTotal: Double {
        SpendStats.total(inMonthOf: .now, entries: sessions.map { (date: $0.date, amount: $0.shoppingTotal) })
    }
    private var monthCount: Int {
        sessions.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    spendCard
                    if !favourites.isEmpty { favouritesSection }
                    pastPreps
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background { AppBackground() }
            .navigationTitle("History")
            .navigationDestination(for: MealRoute.self) { route in
                if let recipe = model.catalog.recipe(route.recipeId) {
                    MealDetailView(recipe: recipe, portions: route.portions)
                }
            }
        }
    }

    private var spendCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spent this month").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            PriceText(value: monthTotal)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("\(monthCount) preps · \(sessions.first.map { "last: \($0.recipeName)" } ?? "none yet")")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Theme.brandGradient, in: .rect(cornerRadius: 28))
        .glassEffect(.clear, in: .rect(cornerRadius: 28))
        .shadow(color: Color(hex: "FF5E9C").opacity(0.35), radius: 16, y: 8)
    }

    private var favouritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Favourites", systemImage: "heart.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favourites) { favourite in
                        if let recipe = model.catalog.recipe(favourite.recipeId) {
                            NavigationLink(value: MealRoute(recipeId: recipe.id)) {
                                MealCard(recipe: recipe, quote: model.quotes[recipe.id], isFavourite: true, height: 190)
                                    .frame(width: 165)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, -16)
        }
    }

    private var pastPreps: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Past preps")
            if sessions.isEmpty {
                Text("Finished preps show up here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardBackground()
            }
            ForEach(sessions) { session in
                NavigationLink(value: MealRoute(recipeId: session.recipeId, portions: session.portions)) {
                    HistoryRow(session: session, recipe: model.catalog.recipe(session.recipeId))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        context.delete(session)
                        try? context.save()
                    }
                }
                .accessibilityHint("Prep again")
            }
        }
    }
}

private struct HistoryRow: View {
    let session: PrepSession
    let recipe: Recipe?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let recipe {
                    RecipePhoto(recipe: recipe, emojiSize: 26)
                } else {
                    Text(session.emoji).font(.title)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(.rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.recipeName).font(.rounded(.subheadline)).lineLimit(1)
                Text("\(session.date.formatted(date: .abbreviated, time: .omitted)) · \(session.storeName)")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.shoppingTotal.kr()).font(.rounded(.subheadline)).monospacedDigit()
                Text("\(session.costPerPortion.kr()) / portion").font(.caption).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(12)
        .cardBackground(cornerRadius: 22)
    }
}
