//
//  VideoProcessing.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 04/06/26.
//
import UIKit
internal import WebKit
internal import Speech
import AVFoundation

extension LiveViewController {

    func extractAndProcess(videoURL: URL) {
        guard let exportSession = AVAssetExportSession(
            asset: AVURLAsset(url: videoURL),
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            self.processingAlert?.dismiss(animated: true)
            captionLabel.text = "Error: Could not process video"; return
        }

        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("live_extracted_audio.m4a")
        try? FileManager.default.removeItem(at: audioURL)

        Task {
            do {
                try await exportSession.export(to: audioURL, as: .m4a)
                await MainActor.run {
                    self.processingAlert?.message = "Recognizing speech..."
                    self.captionLabel.text = "Recognizing speech..."
                    self.recognizeAudioFile(url: audioURL)
                }
            } catch {
                await MainActor.run {
                    self.processingAlert?.dismiss(animated: true)
                    self.captionLabel.text = "Error extracting audio"
                }
            }
        }
    }

    func recognizeAudioFile(url: URL) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self else { return }
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.processingAlert?.dismiss(animated: true)
                    self.captionLabel.text = "Speech permission denied"
                }
                return
            }
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = false

            self.speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if error != nil {
                    DispatchQueue.main.async {
                        self.processingAlert?.dismiss(animated: true)
                        self.captionLabel.text = "Recognition failed"
                    }
                    return
                }
                guard let result, result.isFinal else { return }
                self.pendingSegments = result.bestTranscription.segments
                DispatchQueue.main.async {
                    self.processingAlert?.dismiss(animated: true)
                    self.interpretAndShowCaption()
                }
            }
        }
    }
}
