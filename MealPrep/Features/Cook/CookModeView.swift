import SwiftUI
import SwiftData
import MealPrepCore

struct CookModeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    let basket: Basket
    @State private var index = 0
    @State private var finished = false
    @State private var timers = CookTimers()

    private var isLast: Bool { index == recipe.steps.count - 1 }

    var body: some View {
        ZStack {
            AppBackground()
            if finished {
                PrepDoneView(recipe: recipe, basket: basket,
                             gramsPerPortion: model.nutrition.rawGramsPerPortion(recipe)) {
                    model.finishPrep()
                    dismiss()
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                VStack(spacing: 16) {
                    topBar
                    TabView(selection: $index) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { stepIndex, step in
                            StepCard(step: step, number: stepIndex + 1, total: recipe.steps.count, tint: recipe.tint,
                                     timer: step.timerSeconds.map { timers.timer(for: stepIndex, total: $0) },
                                     onToggleTimer: {
                                         if let seconds = step.timerSeconds {
                                             timers.toggle(step: stepIndex, total: seconds,
                                                           label: "\(recipe.name) – step \(stepIndex + 1)")
                                         }
                                     })
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .tag(stepIndex)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    controls
                }
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.3), value: finished)
        .sensoryFeedback(.selection, trigger: index)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timers.cancelAll()
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.headline).frame(width: 22, height: 22)
                }
                .buttonStyle(.glass)
                RecipePhoto(recipe: recipe, emojiSize: 20)
                    .frame(width: 36, height: 36)
                    .clipShape(.circle)
                Text(recipe.name).font(.rounded(.headline)).lineLimit(1)
                Spacer()
            }
            ProgressView(value: Double(index + 1), total: Double(recipe.steps.count))
                .tint(recipe.tint)
                .animation(.snappy, value: index)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var controls: some View {
        GlassEffectContainer(spacing: 12) {
            HStack {
                Button {
                    withAnimation { index -= 1 }
                } label: {
                    Label("Back", systemImage: "chevron.left").font(.headline)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .disabled(index == 0)
                Spacer()
                Button {
                    if isLast { finish() } else { withAnimation { index += 1 } }
                } label: {
                    Label(isLast ? "Finish" : "Next", systemImage: isLast ? "checkmark" : "chevron.right")
                        .font(.headline)
                        .frame(minWidth: 110)
                }
                .buttonStyle(.glassProminent)
                .tint(recipe.tint)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private func finish() {
        context.insert(PrepSession(recipeId: recipe.id, recipeName: recipe.name, emoji: recipe.emoji,
                                   portions: basket.portions, storeName: basket.displayName,
                                   chainRaw: basket.chain?.rawValue, shoppingTotal: basket.shoppingTotal,
                                   costPerPortion: basket.costPerPortion))
        try? context.save()
        timers.cancelAll()
        Haptics.success()
        finished = true
    }
}
