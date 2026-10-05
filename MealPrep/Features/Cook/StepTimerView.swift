import SwiftUI
import MealPrepCore

struct StepTimerView: View {
    let timer: CookTimer
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let remaining = timer.remaining(at: context.date)
            let finished = timer.isRunning && remaining <= 0
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(tint.opacity(0.18), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: timer.total > 0 ? remaining / timer.total : 0)
                        .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: remaining)
                    Text(finished ? "Done" : Self.format(remaining))
                        .font(.rounded(.title3))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                .frame(width: 110, height: 110)
                .padding(8)
                .glassEffect(.regular, in: .circle)
                Button(action: onToggle) {
                    Label(title(remaining: remaining, finished: finished),
                          systemImage: timer.isRunning && !finished ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .frame(minWidth: 120)
                }
                .buttonStyle(.glassProminent)
                .tint(tint)
                .controlSize(.large)
            }
            .sensoryFeedback(.success, trigger: finished) { _, new in new }
        }
    }

    private func title(remaining: TimeInterval, finished: Bool) -> String {
        if finished { return "Restart" }
        if timer.isRunning { return "Pause" }
        return remaining < timer.total ? "Resume" : "Start timer"
    }

    static func format(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }
}
