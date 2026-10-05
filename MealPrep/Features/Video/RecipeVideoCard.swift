import SwiftUI
import MealPrepCore

extension RecipeVideo {
    /// Title without hashtags.
    var cleanTitle: String {
        title.replacing(/#\S+/, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var durationText: String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}

struct RecipeVideoCard: View {
    let video: RecipeVideo
    let tint: Color
    @State private var playing = false

    var body: some View {
        Button {
            Haptics.selection()
            playing = true
        } label: {
            HStack(spacing: 14) {
                AsyncImage(url: video.thumbnailURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    tint.opacity(0.25)
                }
                .frame(width: 76, height: 100)
                .clipShape(.rect(cornerRadius: 16))
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(12)
                        .glassEffect(.regular.tint(tint.opacity(0.4)), in: .circle)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Watch how it's made").font(.rounded(.headline))
                    Text(video.cleanTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Label("\(video.durationText) · \(video.author)", systemImage: "play.rectangle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .cardBackground(cornerRadius: 24)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $playing) {
            VideoPlayerSheet(video: video, tint: tint)
        }
        .onAppear {
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "debugPlayVideo") { playing = true }
            #endif
        }
    }
}

struct VideoPlayerSheet: View {
    let video: RecipeVideo
    let tint: Color
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline).frame(width: 22, height: 22)
                    }
                    .buttonStyle(.glass)
                    Spacer()
                    Button { openURL(video.watchURL) } label: {
                        Label("Open in YouTube", systemImage: "arrow.up.right").font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
                YouTubePlayer(videoId: video.id)
                    .aspectRatio(9 / 16, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 26))
                    .frame(maxHeight: .infinity)
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.cleanTitle).font(.rounded(.headline)).foregroundStyle(.white).lineLimit(2)
                    Text("\(video.author) · \(video.durationText)").font(.caption).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .preferredColorScheme(.dark)
    }
}
