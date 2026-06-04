//
//  WebvVew.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//
import UIKit
internal import WebKit
internal import Speech
import AVFoundation

extension LiveViewController: AvatarWebViewProtocol {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadFallbackAvatar()
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadFallbackAvatar()
    }
}

extension LiveViewController {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "avatarDone" else { return }
        if isSpellingMode {
            currentSpellingIndex += 1
            playNextLetterInSpellingMode()
        } else {
            isAvatarAnimating = false
            isAvatarPaused = false
            updatePlaybackControlState()
            playGlossQueue()
        }
    }
}


