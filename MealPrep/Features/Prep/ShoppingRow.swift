import SwiftUI
import MealPrepCore

struct ShoppingRow: View {
    let line: PricedLine
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isChecked ? Theme.offer : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 3) {
                    Text(line.ingredient.name)
                        .font(.body.weight(.medium))
                        .strikethrough(isChecked)
                        .foregroundStyle(isChecked ? .secondary : .primary)
                    Text("\(line.packsToBuy) × \(AmountFormatter.format(line.packAmount, line.packUnit)) · \(line.offer?.heading ?? line.ingredient.danishName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    tag
                }
                Spacer()
                Text(line.lineTotal.kr(2))
                    .font(.rounded(.subheadline, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(isChecked ? .secondary : .primary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isChecked ? 0.6 : 1)
        .sensoryFeedback(.selection, trigger: isChecked)
        .animation(.spring(duration: 0.3), value: isChecked)
    }

    @ViewBuilder private var tag: some View {
        if let offer = line.offer {
            let soon = offer.validUntil.timeIntervalSinceNow < 7 * 24 * 3600
            Text("Offer · until \(soon ? offer.validUntil.formatted(.dateTime.weekday(.abbreviated)) : offer.validUntil.formatted(.dateTime.day().month(.abbreviated)))")
                .font(.caption2.bold())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .foregroundStyle(.white)
                .glassEffect(.regular.tint(Theme.offer), in: .capsule)
        } else {
            Text("≈ estimate")
                .font(.caption2.bold())
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .foregroundStyle(.secondary)
                .glassEffect(.regular, in: .capsule)
        }
    }
}
