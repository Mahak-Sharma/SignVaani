// LocalVideoAvatarViewController+WebView.swift

import UIKit
import WebKit
import AVKit

//AvatarWebViewProtocol Conformance
//setupWebView() aur loadFallbackAvatar() ab protocol se aate hain — no duplicate code

//Gloss Playback
extension LocalVideoAvatarViewController:AvatarWebViewProtocol{

    // Send gloss word to JavaScript in the WebView
    func playGloss(_ gloss: String) {
        isPlayingGloss = true
        let normalized = gloss.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized) else {
            print("No animation found for:", normalized)
            isPlayingGloss = false  // ← unblock queue immediately
            return
        }

        let js = "playGlossFromJSON(\(json))"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("JS Error for [\(normalized)]:", error)
                self.isPlayingGloss = false  // unblock on JS failure too
            }
        }
    }
}

//WKNavigationDelegate
extension LocalVideoAvatarViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView started loading")
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("WebView committed")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Avatar webview loaded successfully")
        webView.isHidden = false

        webView.evaluateJavaScript("console.log('WebView ready');") { _, error in
            if let error = error {
                print("JavaScript test failed: \(error)")
            } else {
                print("JavaScript communication established")
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Avatar webview failed to load: \(error)")
        loadFallbackAvatar()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Avatar webview provisional navigation failed: \(error)")
        loadFallbackAvatar()
    }
}

//WKScriptMessageHandler
extension LocalVideoAvatarViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "avatarDone" {
            print("Avatar finished, resuming video")
            isPlayingGloss = false
            //playerViewController?.player?.play()
        }
    }
}
