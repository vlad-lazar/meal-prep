import SwiftUI
import MealPrepCore

struct ChainBadge: View {
    let chain: Chain?

    var body: some View {
        Text(String((chain?.displayName ?? "≈").prefix(1)).uppercased())
            .font(.rounded(.headline))
            .foregroundStyle(chain?.onColor ?? .white)
            .frame(width: 42, height: 42)
            .background(chain?.color ?? .gray, in: .circle)
            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
    }
}

struct StoreRow: View {
    let basket: Basket
    let isBest: Bool
    let isExpanded: Bool
    let onToggle: () -> Void
    let onUse: () -> Void

    private var tint: Color { basket.chain?.color ?? .gray }

    private var subtitle: String {
        var parts: [String] = []
        if let store = basket.store {
            parts.append(formatDistance(store.distanceMeters))
            if let street = store.address.split(separator: ",").first { parts.append(String(street)) }
        }
        return parts.joined(separator: " · ")
    }

    private var offerSummary: String {
        "\(basket.offerCount) on offer · \(basket.estimateCount) estimated"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ChainBadge(chain: basket.chain)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(basket.chain?.displayName ?? basket.displayName).font(.rounded(.headline)).lineLimit(1)
                        if isBest {
                            Text("Best price")
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .foregroundStyle(.white)
                                .glassEffect(.regular.tint(Theme.offer), in: .capsule)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Label(offerSummary, systemImage: "tag")
                        .font(.caption)
                        .foregroundStyle(basket.offerCount > 0 ? Theme.offer : .secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    PriceText(value: basket.shoppingTotal).font(.rounded(.title3))
                    Text("\(basket.costPerPortion.kr()) / portion").font(.caption).foregroundStyle(.secondary)
                }
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(basket.countedLines.filter(\.isOffer)) { line in
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "tag.fill").font(.caption).foregroundStyle(Theme.offer)
                            VStack(alignment: .leading) {
                                Text(line.ingredient.name).font(.subheadline.weight(.medium))
                                Text(line.offer?.heading ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(line.lineTotal.kr(2)).font(.subheadline).monospacedDigit()
                        }
                    }
                    if basket.offerCount == 0 {
                        Text("No matching offers this week — prices are typical estimates.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button(action: onUse) {
                        Label("Use this store", systemImage: "cart.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(basket.chain?.onColor ?? .white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(tint)
                    .controlSize(.large)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(tint.opacity(isExpanded ? 0.16 : 0.06)).interactive(), in: .rect(cornerRadius: 26))
        .contentShape(.rect(cornerRadius: 26))
        .onTapGesture(perform: onToggle)
    }
}

struct StoreRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle().frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 6) {
                Text("Netto Nørrebrogade").font(.headline)
                Text("450 m · 3 on offer").font(.caption)
            }
            Spacer()
            Text("123 kr").font(.title3)
        }
        .padding(16)
        .shimmering()
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }
}
