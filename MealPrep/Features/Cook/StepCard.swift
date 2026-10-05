import SwiftUI
import MealPrepCore

struct StepCard: View {
    let step: Step
    let number: Int
    let total: Int
    let tint: Color
    let portions: Int
    let basePortions: Int
    let timer: CookTimer?
    let onToggleTimer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Step \(number) of \(total)")
                .font(.rounded(.headline))
                .foregroundStyle(tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(tint.opacity(0.15)), in: .capsule)
            Text(StepText.render(step.text, scale: Double(portions) / Double(max(1, basePortions)), portions: portions))
                .font(.system(.title2, design: .rounded, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            if let timer {
                StepTimerView(timer: timer, tint: tint, onToggle: onToggleTimer)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 32))
    }
}
