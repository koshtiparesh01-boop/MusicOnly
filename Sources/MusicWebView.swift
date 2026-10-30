import SwiftUI
import WebKit
import AVFoundation

struct MusicWebView: UIViewRepresentable {
    static let home = URL(string: "https://music.youtube.com")!

    // Hosts the app is allowed to display. Everything else opens in Safari.
    // Google sign-in hosts are needed so you can log in to your account.
    static let allowedHosts: [String] = [
        "music.youtube.com",
        "accounts.google.com",
        "accounts.youtube.com",
        "consent.youtube.com",
        "myaccount.google.com"
    ]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()   // keeps you signed in

        // 1) Inject the ad-skipping / ad-hiding script on every page.
        let script = WKUserScript(source: AdBlock.script,
                                  injectionTime: .atDocumentStart,
                                  forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

        // Keep playing in the background: hide "page hidden" state from the site.
        config.userContentController.addUserScript(
            WKUserScript(source: BackgroundPlay.script,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: true))

        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.attach(webView)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // 2) Compile network-level block rules, then load the site.
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "MusicOnlyAdBlock",
            encodedContentRuleList: AdBlock.rulesJSON
        ) { list, error in
            if let list { webView.configuration.userContentController.add(list) }
            if let error { print("Rule list error:", error) }
            DispatchQueue.main.async {
                webView.load(URLRequest(url: Self.home))
            }
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var webView: WKWebView?
        private var observers: [NSObjectProtocol] = []

        func attach(_ wv: WKWebView) {
            webView = wv
            let nc = NotificationCenter.default

            // Remember whether music was playing just before we leave the foreground.
            observers.append(nc.addObserver(forName: UIApplication.willResignActiveNotification,
                                            object: nil, queue: .main) { [weak self] _ in
                self?.webView?.evaluateJavaScript("window.__moRemember && window.__moRemember()")
            })
            // If iOS/the page paused playback on backgrounding, resume it.
            observers.append(nc.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                            object: nil, queue: .main) { [weak self] _ in
                self?.keepPlaying()
            })
            // Re-activate audio after interruptions (calls, Siri, alarms).
            observers.append(nc.addObserver(forName: AVAudioSession.interruptionNotification,
                                            object: nil, queue: .main) { [weak self] note in
                guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
                self?.keepPlaying()
            })
        }

        private func keepPlaying() {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try? AVAudioSession.sharedInstance().setActive(true)
            for delay in [0.2, 0.8, 2.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.webView?.evaluateJavaScript("window.__moResume && window.__moResume()")
                }
            }
        }

        deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url,
                  let host = url.host?.lowercased() else {
                decisionHandler(.allow); return
            }
            // Sub-resources and iframes are handled by the rule list.
            guard navigationAction.targetFrame?.isMainFrame ?? true else {
                decisionHandler(.allow); return
            }
            let allowed = MusicWebView.allowedHosts.contains { host == $0 || host.hasSuffix("." + $0) }
            if allowed || url.scheme == "about" {
                decisionHandler(.allow)
            } else {
                // Keep the app YouTube-Music-only: send everything else to Safari.
                decisionHandler(.cancel)
                if url.scheme == "http" || url.scheme == "https" {
                    UIApplication.shared.open(url)
                }
            }
        }

        // Links that try to open a new window load in the same view instead.
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
