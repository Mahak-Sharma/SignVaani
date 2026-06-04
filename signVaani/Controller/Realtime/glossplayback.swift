//
//  glossplayback.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//

import UIKit
internal import WebKit

extension LiveViewController {

    func playGlossQueue() {
        guard !isAvatarAnimating else { return }
        guard !isAvatarPaused else { return }
        while !glossEvents.isEmpty {
            let event = glossEvents.removeFirst()
            if playGloss(event.gloss) { return }
        }
        isAvatarAnimating = false
        updatePlaybackControlState()
    }

    @discardableResult
    func playGloss(_ gloss: String) -> Bool {
        let normalized = gloss.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let existsInDB = DatabaseManager.shared.getAnimationSmart(for: normalized) != nil

        if existsInDB {
            addToCaptionAndHighlight(wordOrLetter: normalized.uppercased(), isCompleteWord: true)
            isSpellingMode = false
        } else {
            isSpellingMode = true
            currentSpellingWord = normalized.uppercased()
            currentSpellingIndex = 0
            needsSpaceBeforeNext = !accumulatedCaption.isEmpty
            playNextLetterInSpellingMode()
            return true
        }

        guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized),
              let data = json.data(using: .utf8),
              let encoded = try? JSONSerialization.jsonObject(with: data),
              let safeData = try? JSONSerialization.data(withJSONObject: encoded),
              let safeString = String(data: safeData, encoding: .utf8)
        else { return false }

        isAvatarAnimating = true
        isAvatarPaused = false
        lastPlayedGloss = normalized
        updatePlaybackControlState()

        webView.evaluateJavaScript("playGlossFromJSON(\(safeString))") { [weak self] _, error in
            if let error = error {
                print("JS Error:", error)
                self?.isAvatarAnimating = false
                self?.updatePlaybackControlState()
                self?.playGlossQueue()
            }
        }
        return true
    }

    func playNextLetterInSpellingMode() {
        guard currentSpellingIndex < currentSpellingWord.count else {
            isSpellingMode = false
            needsSpaceBeforeNext = true
            currentSpellingWord = ""
            currentSpellingIndex = 0
            playGlossQueue()
            return
        }

        let idx = currentSpellingWord.index(currentSpellingWord.startIndex,
                                             offsetBy: currentSpellingIndex)
        let letter = String(currentSpellingWord[idx])

        if currentSpellingIndex == 0 && needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }

        let oldLength = accumulatedCaption.count
        accumulatedCaption += letter
        updateCaptionDisplay(highlightRange: NSRange(location: oldLength, length: 1))

        playSingleLetter(letter) { [weak self] success in
            guard let self else { return }
            if !success {
                self.currentSpellingIndex += 1
                self.playNextLetterInSpellingMode()
            }
        }
    }

    func playSingleLetter(_ letter: String, completion: ((Bool) -> Void)?) {
        let normalized = letter.lowercased()
        guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized),
              let data = json.data(using: .utf8),
              let encoded = try? JSONSerialization.jsonObject(with: data),
              let safeData = try? JSONSerialization.data(withJSONObject: encoded),
              let safeString = String(data: safeData, encoding: .utf8)
        else { completion?(false); return }

        isAvatarAnimating = true
        isAvatarPaused = false
        updatePlaybackControlState()

        webView.evaluateJavaScript("playGlossFromJSON(\(safeString))") { [weak self] _, error in
            if let error = error {
                self?.isAvatarAnimating = false
                self?.updatePlaybackControlState()
                completion?(false)
            } else {
                completion?(true)
            }
        }
    }
}
