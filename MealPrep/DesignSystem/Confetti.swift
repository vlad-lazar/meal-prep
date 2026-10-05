import SwiftUI

struct ConfettiView: View {
    let colors: [Color]
    @State private var particles: [Particle] = []
    @State private var start = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Particle {
        let x: Double, speed: Double, drift: Double, spin: Double, size: Double, delay: Double
        let color: Color
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    for particle in particles {
                        let t = elapsed - particle.delay
                        guard t > 0 else { continue }
                        let y = -20 + t * particle.speed
                        guard y < size.height + 20 else { continue }
                        var ctx = context
                        ctx.translateBy(x: particle.x * size.width + sin(t * 2 + particle.drift) * 30, y: y)
                        ctx.rotate(by: .radians(t * particle.spin))
                        ctx.fill(Path(CGRect(x: -particle.size / 2, y: -particle.size / 4,
                                             width: particle.size, height: particle.size / 2)),
                                 with: .color(particle.color))
                    }
                }
            }
            .allowsHitTesting(false)
            .onAppear {
                start = .now
                particles = (0..<140).map { _ in
                    Particle(x: .random(in: 0...1), speed: .random(in: 180...420), drift: .random(in: 0...6),
                             spin: .random(in: -6...6), size: .random(in: 7...13), delay: .random(in: 0...0.8),
                             color: colors.randomElement() ?? .pink)
                }
            }
        }
    }
}
