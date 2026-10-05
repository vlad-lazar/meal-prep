import SwiftUI
import MealPrepCore

struct ShoppingListView: View {
    @Environment(AppModel.self) private var model
    let prep: ActivePrep
    let recipe: Recipe
    @State private var showPantry = false
    @State private var cooking = false
    @State private var confirmDiscard = false

    private struct ShopGroup: Identifiable {
        let section: ShopSection
        let lines: [PricedLine]
        var id: ShopSection { section }
    }

    private var sections: [ShopGroup] {
        Dictionary(grouping: prep.shoppingLines, by: \.ingredient.section)
            .sorted { $0.key.sortIndex < $1.key.sortIndex }
            .map { ShopGroup(section: $0.key, lines: $0.value) }
    }
    private var pantryLines: [PricedLine] { prep.basket.lines.filter(\.ingredient.isPantry) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                ForEach(sections) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.section.title).font(.rounded(.headline)).padding(.leading, 4)
                        VStack(spacing: 0) {
                            ForEach(Array(group.lines.enumerated()), id: \.element.id) { index, line in
                                ShoppingRow(line: line, isChecked: prep.checked.contains(line.id)) {
                                    withAnimation(.snappy) { model.toggleChecked(line.id) }
                                }
                                if index < group.lines.count - 1 { Divider() }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .cardBackground(cornerRadius: 24)
                    }
                }
                if !pantryLines.isEmpty { pantry }
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .scrollIndicators(.hidden)
        .background { AppBackground() }
        .navigationTitle("Shopping list")
        .safeAreaInset(edge: .bottom) { bottomBar }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Discard this prep", systemImage: "trash", role: .destructive) { confirmDiscard = true }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .confirmationDialog("Discard this shopping list?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { model.discardPrep() }
        }
        .fullScreenCover(isPresented: $cooking) {
            CookModeView(recipe: recipe, basket: prep.basket)
        }
        .onAppear {
            #if DEBUG
            if DebugLaunch.cook { cooking = true }
            #endif
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            RecipePhoto(recipe: recipe, emojiSize: 36)
                .frame(width: 68, height: 68)
                .clipShape(.rect(cornerRadius: 20))
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name).font(.rounded(.headline))
                Text("\(prep.portions) portions · \(prep.basket.displayName)")
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                ProgressView(value: prep.progress)
                    .tint(recipe.tint)
                    .animation(.snappy, value: prep.progress)
            }
        }
        .padding(14)
        .cardBackground(cornerRadius: 26)
    }

    private var pantry: some View {
        VStack(alignment: .leading, spacing: 8) {
            DisclosureGroup(isExpanded: $showPantry.animation(.snappy)) {
                VStack(spacing: 4) {
                    ForEach(pantryLines) { line in
                        Toggle(isOn: Binding(
                            get: { !prep.basket.pantryOverrides.contains(line.id) },
                            set: { have in withAnimation(.snappy) { model.setHaveAtHome(line.id, have) } }
                        )) {
                            VStack(alignment: .leading) {
                                Text(line.ingredient.name)
                                Text(AmountFormatter.format(line.neededAmount, line.neededUnit))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .tint(recipe.tint)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("Have at home?", systemImage: "house").font(.rounded(.headline))
            }
            .padding(16)
            .cardBackground(cornerRadius: 24)
            Text("Switch off anything you need to buy — it moves into your list.")
                .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
        }
    }

    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total").font(.caption).foregroundStyle(.secondary)
                PriceText(value: prep.basket.shoppingTotal, fractionDigits: 2).font(.rounded(.title3))
            }
            Spacer()
            Button { cooking = true } label: {
                Label(prep.remainingCount == 0 ? "Start cooking" : "Cook anyway", systemImage: "frying.pan")
                    .font(.headline)
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(recipe.tint)
            .symbolEffect(.bounce, value: prep.remainingCount == 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
