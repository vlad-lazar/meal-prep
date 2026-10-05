import SwiftUI
import MealPrepCore

struct FilterBar: View {
    @Binding var filter: MealFilter
    let cuisines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        Chip(title: filter.maxCostPerPortion.map { "≤ \(Int($0)) kr" } ?? "Price",
                             systemImage: "banknote", isOn: filter.maxCostPerPortion != nil) {
                            filter.maxCostPerPortion = filter.maxCostPerPortion == nil ? 30 : nil
                        }
                        Chip(title: filter.maxMinutes.map { "≤ \($0) min" } ?? "Time",
                             systemImage: "clock", isOn: filter.maxMinutes != nil) {
                            filter.maxMinutes = filter.maxMinutes == nil ? 30 : nil
                        }
                        ForEach(Difficulty.allCases) { difficulty in
                            Chip(title: difficulty.label, isOn: filter.difficulties.contains(difficulty)) {
                                filter.difficulties.formSymmetricDifference([difficulty])
                            }
                        }
                        ForEach(cuisines, id: \.self) { cuisine in
                            Chip(title: cuisine, isOn: filter.cuisines.contains(cuisine)) {
                                filter.cuisines.formSymmetricDifference([cuisine])
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, -16)

            if let maxCost = filter.maxCostPerPortion {
                SliderRow(title: "Max price per portion", valueText: "\(Int(maxCost)) kr",
                          value: Binding(get: { maxCost }, set: { filter.maxCostPerPortion = $0 }),
                          range: 10...60, step: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if let maxMinutes = filter.maxMinutes {
                SliderRow(title: "Max cooking time", valueText: "\(maxMinutes) min",
                          value: Binding(get: { Double(maxMinutes) }, set: { filter.maxMinutes = Int($0) }),
                          range: 15...120, step: 5)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private struct SliderRow: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(valueText)
                    .font(.rounded(.subheadline))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            Slider(value: $value, in: range, step: step).tint(Theme.accent)
        }
        .padding(14)
        .cardBackground()
    }
}
