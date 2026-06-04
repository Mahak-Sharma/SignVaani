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

    func setupAvatarPlaybackControls() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 24
        blurView.clipsToBounds = true
        outerView.addSubview(blurView)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(stack)

        let restart = makeAvatarControlButton(symbolName: "arrow.counterclockwise",
                                              action: #selector(restartButtonTapped),
                                              accessibilityLabel: "Restart avatar")
        let playPause = makeAvatarControlButton(symbolName: "play.fill",
                                                action: #selector(playPauseButtonTapped),
                                                accessibilityLabel: "Play or pause avatar")
        stack.addArrangedSubview(restart)
        stack.addArrangedSubview(playPause)

        NSLayoutConstraint.activate([
            blurView.centerXAnchor.constraint(equalTo: outerView.centerXAnchor),
            blurView.bottomAnchor.constraint(equalTo: outerView.bottomAnchor, constant: -12),
            blurView.heightAnchor.constraint(equalToConstant: 48),
            blurView.widthAnchor.constraint(equalToConstant: 112),
            stack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -6)
        ])

        self.playbackControlsView = blurView
        self.restartButton = restart
        self.playPauseButton = playPause
        updatePlaybackControlState()
    }

    func makeAvatarControlButton(symbolName: String, action: Selector,
                                  accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbolName)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        config.baseForegroundColor = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
        button.configuration = config
        button.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
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

    @objc func restartButtonTapped() {
        runAvatarJavaScript("stopGlossPlayback()")
        isAvatarAnimating = false; isAvatarPaused = false
        isSpellingMode = false; currentSpellingWord = ""; currentSpellingIndex = 0
        currentQueueIndex = 0; lastPlayedGloss = nil
        glossEvents = originalGlossEvents
        currentGlossQueue = originalGlossEvents.map { $0.gloss.uppercased() }
        accumulatedCaption = ""; needsSpaceBeforeNext = false
        captionLabel.attributedText = nil
        updatePlaybackControlState()
        if !glossEvents.isEmpty { playGlossQueue() }
    }

    @objc func playPauseButtonTapped() {
        if isAvatarAnimating {
            isAvatarAnimating = false; isAvatarPaused = true
            updatePlaybackControlState()
            runAvatarJavaScript("pauseGlossPlayback()")
            return
        }
        if isAvatarPaused {
            isAvatarAnimating = true; isAvatarPaused = false
            updatePlaybackControlState()
            runAvatarJavaScript("resumeGlossPlayback()") { [weak self] success in
                if !success {
                    self?.isAvatarAnimating = false; self?.isAvatarPaused = true
                    self?.updatePlaybackControlState()
                }
            }
            return
        }
        glossEvents.isEmpty ? replayLastPlayedGloss() : playGlossQueue()
    }
}
