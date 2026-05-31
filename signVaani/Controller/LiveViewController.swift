import UIKit
import WebKit
import Speech
import AVFoundation

class LiveViewController: UIViewController {
    
    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var captionView: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var micButton: UIButton!
    
    // CHANGE 1: Video URL property — agar set hai toh video mode, nahi toh mic mode
    var incomingVideoURL: URL?
    
    //Speech Recognition Properties
    private let glossProcessor = GlossProcessor()
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var pendingSegments: [SFTranscriptionSegment] = []
    private var glossEvents: [GlossEvent] = []
    private var lastProcessedSegment = 0
    private var isListening = false
    private var isAvatarAnimating = false
    private var isAvatarPaused = false
    private var lastPlayedGloss: String?
    private var playbackControlsView: UIVisualEffectView?
    private var restartButton: UIButton?
    private var playPauseButton: UIButton?
    
    // ========== PROGRESSIVE CAPTION BUILDING PROPERTIES ==========
    private var accumulatedCaption: String = ""
    private var currentGlossQueue: [String] = []
    private var currentQueueIndex: Int = 0
    private var isSpellingMode: Bool = false
    private var currentSpellingWord: String = ""
    private var currentSpellingIndex: Int = 0
    private var scrollTimer: Timer?
    private var needsSpaceBeforeNext: Bool = false
    // ============================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        captionView.layer.cornerRadius = 20
        
        setupWebView()
        webView.configuration.userContentController.add(self, name: "avatarDone")
        
        setupMicButton()
        setupCaptionLabel()
        setupAvatarPlaybackControls()
        
        recordView.layer.cornerRadius = 6
        outerView.layer.cornerRadius = 25
        outerView.clipsToBounds = true
        
        // ✅ CHANGE 2: Agar video URL mila toh mic hide karo aur auto start karo
        if let videoURL = incomingVideoURL {
            micButton.isHidden = true
            recordView.isHidden = true
            captionLabel.text = "Extracting audio..."
            extractAndProcess(videoURL: videoURL)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        _ = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientLayer" })
        
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 234/255, green: 242/255, blue: 255/255, alpha: 1).cgColor,
            UIColor(red: 163/255, green: 198/255, blue: 255/255, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.7]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = view.bounds
        gradient.name = "gradientLayer"
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private func setupMicButton() {
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        micButton.layer.cornerRadius = micButton.frame.height / 2
        micButton.clipsToBounds = true
    }
    
    private func setupCaptionLabel() {
        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byClipping
        captionLabel.adjustsFontSizeToFitWidth = false
    }
    
    private func setupAvatarPlaybackControls() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 24
        blurView.clipsToBounds = true
        outerView.addSubview(blurView)
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(stackView)
        
        let restartButton = makeAvatarControlButton(
            symbolName: "arrow.counterclockwise",
            action: #selector(restartButtonTapped),
            accessibilityLabel: "Restart avatar"
        )
        let playPauseButton = makeAvatarControlButton(
            symbolName: "play.fill",
            action: #selector(playPauseButtonTapped),
            accessibilityLabel: "Play or pause avatar"
        )
        
        stackView.addArrangedSubview(restartButton)
        stackView.addArrangedSubview(playPauseButton)
        
        NSLayoutConstraint.activate([
            blurView.centerXAnchor.constraint(equalTo: outerView.centerXAnchor),
            blurView.bottomAnchor.constraint(equalTo: outerView.bottomAnchor, constant: -12),
            blurView.heightAnchor.constraint(equalToConstant: 48),
            blurView.widthAnchor.constraint(equalToConstant: 112),
            
            stackView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -6),
            stackView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 6),
            stackView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -6)
        ])
        
        self.playbackControlsView = blurView
        self.restartButton = restartButton
        self.playPauseButton = playPauseButton
        
        updatePlaybackControlState()
    }
    
    private func makeAvatarControlButton(symbolName: String,
                                         action: Selector,
                                         accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbolName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        configuration.baseForegroundColor = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
        button.configuration = configuration
        button.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.accessibilityLabel = accessibilityLabel
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func updatePlaybackControlState() {
        let playPauseSymbol = isAvatarAnimating ? "pause.fill" : "play.fill"
        if var configuration = playPauseButton?.configuration {
            configuration.image = UIImage(systemName: playPauseSymbol)
            playPauseButton?.configuration = configuration
        }
        
        let hasPlaybackContext = isAvatarAnimating || isAvatarPaused || !glossEvents.isEmpty || lastPlayedGloss != nil
        let canRestart = isAvatarAnimating || isAvatarPaused || !glossEvents.isEmpty || lastPlayedGloss != nil
        
        playPauseButton?.isEnabled = hasPlaybackContext
        restartButton?.isEnabled = canRestart
        
        restartButton?.alpha = canRestart ? 1.0 : 0.45
        playPauseButton?.alpha = hasPlaybackContext ? 1.0 : 0.45
    }
    
    private func runAvatarJavaScript(_ script: String, completion: ((Bool) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Avatar JS command failed:", error)
                completion?(false)
                return
            }
            completion?(true)
        }
    }
    
    private func stopAvatarPlayback(clearQueue: Bool = false, clearLastGloss: Bool = false) {
        if clearQueue {
            glossEvents.removeAll()
            resetCaptionBuilding()
        }
        
        if clearLastGloss {
            lastPlayedGloss = nil
        }
        
        isAvatarAnimating = false
        isAvatarPaused = false
        updatePlaybackControlState()
        runAvatarJavaScript("stopGlossPlayback()")
    }
    
    private func replayLastPlayedGloss() {
        guard lastPlayedGloss != nil else { return }
        
        isAvatarPaused = false
        isAvatarAnimating = true
        updatePlaybackControlState()
        
        runAvatarJavaScript("replayLastGloss()") { [weak self] success in
            guard let self = self else { return }
            if !success {
                self.isAvatarAnimating = false
                self.updatePlaybackControlState()
            }
        }
    }
    
    @objc private func restartButtonTapped() {
        resetCaptionBuilding()
        
        if isAvatarAnimating || isAvatarPaused || lastPlayedGloss != nil {
            isAvatarAnimating = true
            isAvatarPaused = false
            updatePlaybackControlState()
            runAvatarJavaScript("restartGlossPlayback()") { [weak self] success in
                guard let self = self else { return }
                if !success {
                    self.isAvatarAnimating = false
                    self.updatePlaybackControlState()
                }
            }
            return
        }
        
        if !glossEvents.isEmpty {
            playGlossQueue()
        }
    }
    
    @objc private func playPauseButtonTapped() {
        if isAvatarAnimating {
            isAvatarAnimating = false
            isAvatarPaused = true
            updatePlaybackControlState()
            runAvatarJavaScript("pauseGlossPlayback()")
            return
        }
        
        if isAvatarPaused {
            isAvatarAnimating = true
            isAvatarPaused = false
            updatePlaybackControlState()
            runAvatarJavaScript("resumeGlossPlayback()") { [weak self] success in
                guard let self = self else { return }
                if !success {
                    self.isAvatarAnimating = false
                    self.isAvatarPaused = true
                    self.updatePlaybackControlState()
                }
            }
            return
        }
        
        if !glossEvents.isEmpty {
            playGlossQueue()
        } else {
            replayLastPlayedGloss()
        }
    }
    
    @IBAction func micButtonTapped(_ sender: UIButton) {
        if isListening {
            stopSpeechRecognition()
        } else {
            requestPermissionsAndStart()
        }
    }
    
    private func requestPermissionsAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.showPermissionAlert(
                        title: "Speech Permission Required",
                        message: "Go to the Setting and please allow the permission"
                    )
                }
                return
            }
            
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startSpeechRecognition()
                    } else {
                        self.showPermissionAlert(
                            title: "Microphone Permission Required",
                            message: "Go to the Setting and please allow the permission"
                        )
                    }
                }
            }
        }
    }
    
    private func showPermissionAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func startSpeechRecognition() {
        lastProcessedSegment = 0
        pendingSegments.removeAll()
        stopAvatarPlayback(clearQueue: true, clearLastGloss: true)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord,
                                         mode: .measurement,
                                         options: [.defaultToSpeaker, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSession setup error:", error)
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Recognition error:", error.localizedDescription)
                return
            }
            guard let result = result else { return }
            
            if result.isFinal {
                print("Final result:", result.bestTranscription.formattedString)
                let segments = result.bestTranscription.segments
                self.pendingSegments = segments
                self.lastProcessedSegment = segments.count
                
                DispatchQueue.main.async {
                    self.captionLabel.text = "Processing..."
                }
            } else {
                print("Partial:", result.bestTranscription.formattedString)
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            
            DispatchQueue.main.async {
                self.micButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                
                self.recordView.layer.sublayers?.filter { $0.name == "pulse" }.forEach { $0.removeFromSuperlayer() }
                
                for i in 0..<3 {
                    let pulseLayer = CALayer()
                    pulseLayer.name = "pulse"
                    pulseLayer.frame = self.recordView.bounds
                    pulseLayer.cornerRadius = self.recordView.layer.cornerRadius
                    pulseLayer.backgroundColor = UIColor.systemGreen.cgColor
                    
                    let scale = CABasicAnimation(keyPath: "transform.scale")
                    scale.fromValue = 1.0
                    scale.toValue = 2.5
                    
                    let fade = CABasicAnimation(keyPath: "opacity")
                    fade.fromValue = 0.5
                    fade.toValue = 0.0
                    
                    let group = CAAnimationGroup()
                    group.animations = [scale, fade]
                    group.duration = 1.5
                    group.repeatCount = .infinity
                    group.beginTime = CACurrentMediaTime() + Double(i) * 0.5
                    group.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    
                    self.recordView.layer.insertSublayer(pulseLayer, at: 0)
                    pulseLayer.add(group, forKey: "pulse")
                }
                
                self.captionLabel.text = "Listening..."
            }
            
            print("Speech recognition started")
        } catch {
            print("Audio engine failed:", error)
        }
    }
    
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        isListening = false
        
        DispatchQueue.main.async {
            self.micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            self.recordView.layer.sublayers?.filter { $0.name == "pulse" }.forEach { $0.removeFromSuperlayer() }
            self.recordView.backgroundColor = .lightGray
            self.captionLabel.text = "Processing..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.interpretAndShowCaption()
        }
    }
    
    private func interpretAndShowCaption() {
        guard !pendingSegments.isEmpty else {
            captionLabel.text = "Tap mic to start"
            return
        }
        
        let segmentsToProcess = pendingSegments
        pendingSegments.removeAll()
        
        let spokenText = segmentsToProcess
            .map { $0.substring }
            .joined(separator: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        
        print("Original spoken text:", spokenText)
        
        let events = glossProcessor.extractGlossTimeline(from: segmentsToProcess)
        let glossText = events
            .map { $0.gloss.uppercased() }
            .joined(separator: " ")
        
        print("Gloss caption:", glossText)
        
        resetCaptionBuilding()
        
        if DatabaseManager.shared.getAnimationSmart(for: spokenText) != nil {
            print("Direct sentence animation found:", spokenText)
            glossEvents.removeAll()
            playGloss(spokenText)
            return
        }
        
        glossEvents.removeAll()
        glossEvents.append(contentsOf: events)
        
        currentGlossQueue = events.map { $0.gloss.uppercased() }
        currentQueueIndex = 0
        needsSpaceBeforeNext = false
        accumulatedCaption = ""
        captionLabel.attributedText = nil
        
        if !glossEvents.isEmpty && !isAvatarAnimating && !isAvatarPaused {
            playGlossQueue()
        }
    }
    
    // CHANGE 3: Video se audio extract karke speech recognition chalao
    private func extractAndProcess(videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            print("Export session create nahi hua")
            captionLabel.text = "Error: Could not process video"
            return
        }
        
        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("live_extracted_audio.m4a")
        try? FileManager.default.removeItem(at: audioURL)
        
        Task {
            do {
                try await exportSession.export(to: audioURL, as: .m4a)
                print("Audio extract ho gaya")
                await MainActor.run {
                    self.captionLabel.text = " Recognizing speech..."
                    self.recognizeAudioFile(url: audioURL)
                }
            } catch {
                print("Audio extract failed:", error)
                await MainActor.run {
                    self.captionLabel.text = "Error extracting audio"
                }
            }
        }
    }
    
    private func recognizeAudioFile(url: URL) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.captionLabel.text = "Speech permission denied"
                }
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = false
            
            self.speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Recognition error:", error)
                    DispatchQueue.main.async {
                        self.captionLabel.text = "Recognition failed"
                    }
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                print("Recognized text:", result.bestTranscription.formattedString)
                let segments = result.bestTranscription.segments
                
                // Mic wala same flow — segments se gloss banao aur avatar chalao
                self.pendingSegments = segments
                
                DispatchQueue.main.async {
                    self.interpretAndShowCaption()
                }
            }
        }
    }
    
    private func playGlossQueue() {
        guard !isAvatarAnimating else { return }
        guard !isAvatarPaused else { return }
        
        while !glossEvents.isEmpty {
            let event = glossEvents.removeFirst()
            
            if playGloss(event.gloss) {
                return
            }
        }
        
        isAvatarAnimating = false
        updatePlaybackControlState()
    }
    
    // ========== PROGRESSIVE CAPTION BUILDING METHODS ==========
    
    private func resetCaptionBuilding() {
        stopScrolling()
        accumulatedCaption = ""
        currentGlossQueue.removeAll()
        currentQueueIndex = 0
        isSpellingMode = false
        currentSpellingWord = ""
        currentSpellingIndex = 0
        needsSpaceBeforeNext = false
        captionLabel.attributedText = nil
    }
    
    private func addToCaptionAndHighlight(wordOrLetter: String, isCompleteWord: Bool) {
        if needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }
        
        let oldLength = accumulatedCaption.count
        accumulatedCaption += wordOrLetter
        
        let highlightRange: NSRange
        if isCompleteWord {
            highlightRange = NSRange(location: oldLength, length: wordOrLetter.count)
        } else {
            highlightRange = NSRange(location: accumulatedCaption.count - 1, length: 1)
        }
        
        updateCaptionDisplay(highlightRange: highlightRange)
        
        if isCompleteWord {
            needsSpaceBeforeNext = true
        }
    }
    
    private func updateCaptionDisplay(highlightRange: NSRange) {
        let attributedString = NSMutableAttributedString(string: accumulatedCaption)
        
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.black,
                                      range: NSRange(location: 0, length: accumulatedCaption.count))
        
        if highlightRange.location + highlightRange.length <= accumulatedCaption.count {
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.systemBlue,
                                          range: highlightRange)
        }
        
        captionLabel.attributedText = attributedString
        checkAndScrollCaption()
    }
    
    private func checkAndScrollCaption() {
        guard let attributedText = captionLabel.attributedText else { return }
        
        let textSize = attributedText.size()
        let labelWidth = captionLabel.bounds.width
        
        if textSize.width > labelWidth {
            startScrollingIfNeeded()
        } else {
            stopScrolling()
        }
    }
    
    private func startScrollingIfNeeded() {
        guard scrollTimer == nil else { return }
        
        captionLabel.layer.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0)
        
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentX = self.captionLabel.layer.sublayerTransform.m41
            let textWidth = self.captionLabel.attributedText?.size().width ?? 0
            let labelWidth = self.captionLabel.bounds.width
            
            if textWidth > labelWidth {
                if currentX > -(textWidth - labelWidth) {
                    let newX = currentX - 2
                    self.captionLabel.layer.sublayerTransform = CATransform3DMakeTranslation(newX, 0, 0)
                } else {
                    self.removeFirstWordFromCaption()
                }
            }
        }
    }
    
    private func removeFirstWordFromCaption() {
        if let spaceIndex = accumulatedCaption.firstIndex(of: " ") {
            let range = accumulatedCaption.startIndex...spaceIndex
            accumulatedCaption.removeSubrange(range)
            updateCaptionDisplay(highlightRange: NSRange(location: 0, length: 0))
            captionLabel.layer.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0)
        } else {
            stopScrolling()
        }
    }
    
    private func stopScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        captionLabel.layer.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0)
    }
    
    @discardableResult
    private func playGloss(_ gloss: String) -> Bool {
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
        
        guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized) else {
            print("No animation found for:", normalized)
            return false
        }
        
        print("Playing:", normalized)
        
        if let data = json.data(using: .utf8),
           let encoded = try? JSONSerialization.jsonObject(with: data),
           let safeData = try? JSONSerialization.data(withJSONObject: encoded),
           let safeString = String(data: safeData, encoding: .utf8) {
            
            isAvatarAnimating = true
            isAvatarPaused = false
            lastPlayedGloss = normalized
            updatePlaybackControlState()
            
            let js = "playGlossFromJSON(\(safeString))"
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    print("JS Error:", error)
                    self?.isAvatarAnimating = false
                    self?.updatePlaybackControlState()
                    self?.playGlossQueue()
                } else {
                    print("Successfully playing:", gloss)
                }
            }
        } else {
            return false
        }
        
        return true
    }
    
    private func playNextLetterInSpellingMode() {
        guard currentSpellingIndex < currentSpellingWord.count else {
            isSpellingMode = false
            needsSpaceBeforeNext = true
            currentSpellingWord = ""
            currentSpellingIndex = 0
            playGlossQueue()
            return
        }
        
        let letter = String(currentSpellingWord[currentSpellingWord.index(currentSpellingWord.startIndex, offsetBy: currentSpellingIndex)])
        
        let isFirstLetter = (currentSpellingIndex == 0)
        if isFirstLetter && needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }
        
        let oldLength = accumulatedCaption.count
        accumulatedCaption += letter
        
        let highlightRange = NSRange(location: oldLength, length: 1)
        updateCaptionDisplay(highlightRange: highlightRange)
        
        playSingleLetter(letter) { [weak self] success in
            guard let self = self else { return }
            if !success {
                self.currentSpellingIndex += 1
                self.playNextLetterInSpellingMode()
            }
        }
    }
    
    private func playSingleLetter(_ letter: String, completion: ((Bool) -> Void)?) {
        let normalized = letter.lowercased()
        
        guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized) else {
            print("No animation found for letter:", normalized)
            completion?(false)
            return
        }
        
        if let data = json.data(using: .utf8),
           let encoded = try? JSONSerialization.jsonObject(with: data),
           let safeData = try? JSONSerialization.data(withJSONObject: encoded),
           let safeString = String(data: safeData, encoding: .utf8) {
            
            isAvatarAnimating = true
            isAvatarPaused = false
            updatePlaybackControlState()
            
            let js = "playGlossFromJSON(\(safeString))"
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    print("JS Error for letter:", error)
                    self?.isAvatarAnimating = false
                    self?.updatePlaybackControlState()
                    completion?(false)
                } else {
                    print("Playing letter:", letter)
                    completion?(true)
                }
            }
        } else {
            completion?(false)
        }
    }
}

extension LiveViewController: WKNavigationDelegate, AvatarWebViewProtocol {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("HomeViewController: WebView loaded successfully")
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("HomeViewController: WebView failed - \(error)")
        loadFallbackAvatar()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("HomeViewController: WebView provisional failed - \(error)")
        loadFallbackAvatar()
    }
}

extension LiveViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "avatarDone" {
            print("Avatar animation complete")
            
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
}
