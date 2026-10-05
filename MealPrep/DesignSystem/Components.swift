import SwiftUI
import MealPrepCore

extension View {
    func cardBackground() -> some View {
        background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: Theme.corner))
    }
}

struct Chip: View {
    let title: String
    var systemImage: String?
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).symbolEffect(.bounce, value: isOn)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .background {
                Capsule().fill(isOn ? AnyShapeStyle(Theme.brandGradient)
                                    : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isOn)
    }
}

struct StatPill: View {
    let systemImage: String
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.15), in: .capsule)
            .foregroundStyle(tint)
    }
}

struct DifficultyDots: View {
    let difficulty: Difficulty
    var tint: Color = Theme.accent

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= difficulty.rawValue ? tint : tint.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel(difficulty.label)
    }
}

struct PriceText: View {
    let value: Double
    var fractionDigits = 0

    var body: some View {
        Text(value.kr(fractionDigits))
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
    }
}

struct BannerView: View {
    let text: String
    var systemImage = "exclamationmark.triangle.fill"

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.footnote.weight(.medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.orange.opacity(0.15), in: .rect(cornerRadius: 14))
            .foregroundStyle(.orange)
    }
}
