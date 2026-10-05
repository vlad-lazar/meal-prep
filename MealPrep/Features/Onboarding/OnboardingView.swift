import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    let onFinish: () -> Void
    @State private var page = 0
    @State private var showPostcode = false
    @State private var isLocating = false

    private struct Card {
        let emoji: String
        let title: String
        let text: String
        let colors: [String]
    }

    private let cards = [
        Card(emoji: "🥘", title: "Pick a meal",
             text: "Browse meal-prep recipes by price per portion, cooking time and difficulty.",
             colors: ["FF8A5B", "FF5E9C", "FFC371"]),
        Card(emoji: "🛒", title: "Shop the cheapest store",
             text: "We compare this week's offers at Netto, REMA 1000, Lidl, føtex and more near you.",
             colors: ["34D399", "0EA5E9", "A7F3D0"]),
        Card(emoji: "👩‍🍳", title: "Prep it",
             text: "Tick off your shopping list, then cook step by step with built-in timers.",
             colors: ["A78BFA", "F472B6", "FBCFE8"]),
    ]

    var body: some View {
        TabView(selection: $page) {
            ForEach(cards.indices, id: \.self) { index in
                cardView(index).tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
        .sheet(isPresented: $showPostcode) {
            PostcodeSheet(onSaved: onFinish)
        }
    }

    private func cardView(_ index: Int) -> some View {
        let card = cards[index]
        let isLast = index == cards.count - 1
        let c = card.colors.map(Color.init(hex:))
        return ZStack {
            MeshBackground(colors: [c[0], c[2], c[1], c[1], c[0], c[2], c[2], c[1], c[0]], speed: 0.4)
            VStack(spacing: 26) {
                Spacer()
                Text(card.emoji)
                    .font(.system(size: 96))
                    .frame(width: 180, height: 180)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .scaleEffect(page == index ? 1 : 0.5)
                    .rotationEffect(.degrees(page == index ? 0 : -20))
                    .animation(.spring(duration: 0.6, bounce: 0.5), value: page)
                VStack(spacing: 12) {
                    Text(card.title)
                        .font(.rounded(.largeTitle))
                    Text(card.text)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 6)
                .padding(.horizontal, 28)
                Spacer()
                if isLast {
                    VStack(spacing: 14) {
                        Button {
                            Task { await useLocation() }
                        } label: {
                            Label(isLocating ? "Locating…" : "Use my location", systemImage: "location.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color(hex: card.colors[0]))
                        .controlSize(.large)
                        .disabled(isLocating)
                        Button {
                            showPostcode = true
                        } label: {
                            Text("Enter a postcode instead")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                        Text("Your location is only used to find grocery stores near you.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                } else {
                    Button {
                        withAnimation(.smooth) { page += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
    }

    private func useLocation() async {
        isLocating = true
        await model.locate()
        isLocating = false
        if model.coordinate != nil {
            onFinish()
        } else {
            showPostcode = true
        }
    }
}
