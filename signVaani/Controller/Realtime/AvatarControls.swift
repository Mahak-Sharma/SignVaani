//
//  AvatarControls.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//

import UIKit
internal import WebKit
internal import Speech
import AVFoundation


extension LiveViewController {

    func setupMicButton() {
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        micButton.layer.cornerRadius = micButton.frame.height / 2
        micButton.clipsToBounds = true
    }
    func updatePlaybackControlState() {
        let symbol = isAvatarAnimating ? "pause.fill" : "play.fill"
        if var config = playPauseButton?.configuration {
            config.image = UIImage(systemName: symbol)
            playPauseButton?.configuration = config
        }
        let hasContext = isAvatarAnimating || isAvatarPaused || !glossEvents.isEmpty || lastPlayedGloss != nil
        playPauseButton?.isEnabled = hasContext
        restartButton?.isEnabled = hasContext
        playPauseButton?.alpha = hasContext ? 1.0 : 0.45
        restartButton?.alpha = hasContext ? 1.0 : 0.45
    }

    func runAvatarJavaScript(_ script: String, completion: ((Bool) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { _, error in
            completion?(error == nil)
        }
    }

    func stopAvatarPlayback(clearQueue: Bool = false, clearLastGloss: Bool = false) {
        if clearQueue { glossEvents.removeAll(); resetCaptionBuilding() }
        if clearLastGloss { lastPlayedGloss = nil }
        isAvatarAnimating = false
        isAvatarPaused = false
        updatePlaybackControlState()
        runAvatarJavaScript("stopGlossPlayback()")
    }

    func replayLastPlayedGloss() {
        guard lastPlayedGloss != nil else { return }
        isAvatarPaused = false
        isAvatarAnimating = true
        updatePlaybackControlState()
        runAvatarJavaScript("replayLastGloss()") { [weak self] success in
            if !success {
                self?.isAvatarAnimating = false
                self?.updatePlaybackControlState()
            }
        }
    }
}
