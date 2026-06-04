//
//  Untitled.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//

import UIKit
import Foundation
internal import Speech

extension LiveViewController {

    func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.showPermissionAlert(title: "Speech Permission Required",
                                            message: "Go to Settings and allow permission")
                }
                return
            }
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    granted
                        ? self.startSpeechRecognition()
                        : self.showPermissionAlert(title: "Microphone Permission Required",
                                                   message: "Go to Settings and allow permission")
                }
            }
        }
    }

    func showPermissionAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func startSpeechRecognition() {
        lastProcessedSegment = 0
        pendingSegments.removeAll()
        stopAvatarPlayback(clearQueue: true, clearLastGloss: true)
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement,
                                         options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSession setup error:", error); return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024,
                              format: inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let error = error { print("Recognition error:", error.localizedDescription); return }
            guard let result else { return }

            if result.isFinal {
                let segments = result.bestTranscription.segments
                self.pendingSegments = segments
                self.lastProcessedSegment = segments.count
                DispatchQueue.main.async { self.captionLabel.text = "Processing..." }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            DispatchQueue.main.async { self.updateMicUIForListening(true) }
        } catch {
            print("Audio engine failed:", error)
        }
    }

    func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isListening = false

        DispatchQueue.main.async {
            self.updateMicUIForListening(false)
            self.captionLabel.text = "⏳ Processing..."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.recognitionTask?.cancel()
            self?.recognitionTask = nil
            self?.interpretAndShowCaption()
        }
    }

    func interpretAndShowCaption() {
        guard !pendingSegments.isEmpty else {
            captionLabel.text = "Tap mic to start"; return
        }

        let segmentsToProcess = pendingSegments
        pendingSegments.removeAll()

        let spokenText = segmentsToProcess
            .map { $0.substring }.joined(separator: " ")
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")

        let events = glossProcessor.extractGlossTimeline(from: segmentsToProcess)
        resetCaptionBuilding()

        if DatabaseManager.shared.getAnimationSmart(for: spokenText) != nil {
            playGloss(spokenText)
            return
        }

        glossEvents = events
        originalGlossEvents = events
        currentGlossQueue = events.map { $0.gloss.uppercased() }
        currentQueueIndex = 0
        needsSpaceBeforeNext = false
        accumulatedCaption = ""
        captionLabel.attributedText = nil

        if !glossEvents.isEmpty && !isAvatarAnimating && !isAvatarPaused {
            playGlossQueue()
        }
    }

    // MARK: - Mic UI helper
    private func updateMicUIForListening(_ listening: Bool) {
        if listening {
            micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            recordView.layer.sublayers?.filter { $0.name == "pulse" }.forEach { $0.removeFromSuperlayer() }
            for i in 0..<3 {
                let pulse = CALayer()
                pulse.name = "pulse"
                pulse.frame = recordView.bounds
                pulse.cornerRadius = recordView.layer.cornerRadius
                pulse.backgroundColor = UIColor.systemGreen.cgColor
                let scale = CABasicAnimation(keyPath: "transform.scale")
                scale.fromValue = 1.0; scale.toValue = 2.5
                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = 0.5; fade.toValue = 0.0
                let group = CAAnimationGroup()
                group.animations = [scale, fade]
                group.duration = 1.5; group.repeatCount = .infinity
                group.beginTime = CACurrentMediaTime() + Double(i) * 0.5
                group.timingFunction = CAMediaTimingFunction(name: .easeOut)
                recordView.layer.insertSublayer(pulse, at: 0)
                pulse.add(group, forKey: "pulse")
            }
            captionLabel.text = "Listening..."
        } else {
            micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            recordView.layer.sublayers?.filter { $0.name == "pulse" }.forEach { $0.removeFromSuperlayer() }
            recordView.backgroundColor = .lightGray
        }
    }

//    // MARK: - Single gloss playback helper
//    private func playGloss(_ text: String) {
//        // If there's a direct animation for the full spoken text, play it as a single gloss.
//        if DatabaseManager.shared.getAnimationSmart(for: text) != nil {
//            // Reset any existing state and play this one item
//            stopAvatarPlayback(clearQueue: true, clearLastGloss: true)
//            glossEvents = []
//            originalGlossEvents = []
//            currentGlossQueue = [text.uppercased()]
//            currentQueueIndex = 0
//            needsSpaceBeforeNext = false
//            accumulatedCaption = ""
//            captionLabel.attributedText = nil
//            playGlossQueue()
//            return;
//        }
//
//        // Fallback: build events from the text and play via queue if no direct animation
//        let segments = SFSpeechRecognitionResult()
//        // Since we don't have segments here, use the glossProcessor to build from raw string if supported.
//        // If not supported, just enqueue the uppercased text.
//        if glossEvents.isEmpty {
//            glossEvents = []
//            originalGlossEvents = []
//        }
//        currentGlossQueue = [text.uppercased()]
//        currentQueueIndex = 0
//        playGlossQueue()
//    }
}
