import SwiftUI
import MealPrepCore

extension View {
    /// Frosted Liquid Glass panel used for sections and cards.
    func cardBackground(cornerRadius: CGFloat = Theme.corner) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
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
            .padding(.vertical, 9)
            .foregroundStyle(isOn ? Color.white : Color.primary)
            .glassEffect(isOn ? .regular.tint(Theme.accent).interactive() : .regular.interactive(), in: .capsule)
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
        HStack(spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(tint)
            Text(text).foregroundStyle(.primary)
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .glassEffect(.regular.tint(tint.opacity(0.18)), in: .capsule)
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
        HStack(spacing: 10) {
            Image(systemName: systemImage).foregroundStyle(.orange)
            Text(text).foregroundStyle(.primary)
        }
        .font(.footnote.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .rect(cornerRadius: 18))
    }
}

struct SectionTitle: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage).symbolRenderingMode(.multicolor) }
            Text(text)
        }
        .font(.rounded(.title3))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
