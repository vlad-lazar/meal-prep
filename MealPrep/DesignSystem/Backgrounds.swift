import SwiftUI

/// Slowly drifting 3×3 mesh gradient — the colourful layer Liquid Glass refracts.
struct MeshBackground: View {
    let colors: [Color]
    var speed: Double = 0.25
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate * speed)
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5 + 0.1 * sin(t), 0], [1, 0],
                    [0, 0.5 + 0.1 * cos(t * 0.8)], [0.5 + 0.18 * sin(t * 0.7), 0.5 + 0.12 * cos(t * 0.9)],
                    [1, 0.5 + 0.1 * sin(t * 1.1)],
                    [0, 1], [0.5 + 0.1 * cos(t * 0.6), 1], [1, 1],
                ],
                colors: colors)
        }
        .ignoresSafeArea()
    }
}

/// App-wide background: warm pastels in light mode, deep jewel tones in dark mode.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    private static let light = ["FFE1D2", "FFD3E4", "E7DDFF",
                                "FFE9C7", "FFF6F0", "D9E6FF",
                                "D3F4E6", "FFDDEB", "F0D9FF"].map(Color.init(hex:))
    private static let dark = ["2B1A3D", "3D1D45", "1D2848",
                               "3A2A1C", "17172A", "1F2C46",
                               "16352F", "3A1C33", "2A1E48"].map(Color.init(hex:))

    var body: some View {
        MeshBackground(colors: scheme == .dark ? Self.dark : Self.light)
    }
}
