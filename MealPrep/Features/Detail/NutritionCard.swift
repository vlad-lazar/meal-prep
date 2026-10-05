import SwiftUI
import MealPrepCore

struct NutritionCard: View {
    let facts: NutritionFacts
    let tint: Color
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Nutrition per portion")
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(tint.opacity(0.18), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: appeared ? min(1, facts.kcal / 1000) : 0)
                        .stroke(tint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(facts.kcal.rounded()))").font(.rounded(.title2))
                        Text("kcal").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 110)
                VStack(alignment: .leading, spacing: 10) {
                    MacroBar(name: "Protein", grams: facts.protein, reference: 60, color: .pink, appeared: appeared)
                    MacroBar(name: "Carbs", grams: facts.carbs, reference: 120, color: .orange, appeared: appeared)
                    MacroBar(name: "Fat", grams: facts.fat, reference: 50, color: .purple, appeared: appeared)
                    Text("Fibre \(facts.fibre, format: .number.precision(.fractionLength(1))) g")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .cardBackground()
            Text("Approximate values from standard food composition tables.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 1.0)) { appeared = true }
        }
    }
}

private struct MacroBar: View {
    let name: String
    let grams: Double
    let reference: Double
    let color: Color
    let appeared: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(grams.rounded())) g").font(.caption).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.18))
                    Capsule().fill(color).frame(width: appeared ? geo.size.width * min(1, grams / reference) : 0)
                }
            }
            .frame(height: 8)
        }
    }
}
