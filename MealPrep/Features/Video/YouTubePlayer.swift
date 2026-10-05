import SwiftUI
import WebKit

/// Embedded YouTube player (privacy-enhanced domain). The page gets an https base URL so YouTube
/// receives a referrer — embeds without one fail with "video player configuration error".
struct YouTubePlayer: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        let html = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;height:100%;background:#000}iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style>
        </head><body>
        <iframe src="https://www.youtube-nocookie.com/embed/\(videoId)?playsinline=1&autoplay=1&rel=0&modestbranding=1"
          allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen
          referrerpolicy="strict-origin-when-cross-origin"></iframe>
        </body></html>
        """
        let base = URL(string: "https://\(Bundle.main.bundleIdentifier ?? "mealprep.app")")
        webView.loadHTMLString(html, baseURL: base)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
