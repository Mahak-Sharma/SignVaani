import UIKit
import AVKit
import AVFoundation
import WebKit
import NaturalLanguage
import Speech

class LocalVideoAvatarViewController: UIViewController {
    var captionWords: [String] = []
    var currentCaptionIndex = 0
    var captionSegments: [SFTranscriptionSegment] = []
    
    //Properties
    var glossQueue: [String] = []
    var glossEvents: [GlossEvent] = []
    let glossProcessor = GlossProcessor()
    var isPlayingGloss = false
    var playerViewController: AVPlayerViewController?
    var displayLink: CADisplayLink?
    
    // --- Receive video from UploadOptionsViewController ---
    var selectedVideoURL: URL? {
        didSet {
            print("Video URL received: \(selectedVideoURL?.path ?? "nil")")
        }
    }
    
    // --- Speech recognition properties ---
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    var recognitionRequest: SFSpeechURLRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    
    // ========== PROGRESSIVE CAPTION BUILDING PROPERTIES ==========
    private var accumulatedCaption: String = ""           // Full caption built so far
    private var isSpellingMode: Bool = false              // Currently spelling a word?
    private var currentSpellingWord: String = ""          // Word being spelled (e.g., "HOW")
    private var currentSpellingIndex: Int = 0             // Which letter we're on (0,1,2)
    private var scrollTimer: Timer?                       // For horizontal scrolling
    private var needsSpaceBeforeNext: Bool = false        // Add space before next word/letter
    private var currentWordStartTime: Double = 0          // For timing spelling mode
    private var currentWordDuration: Double = 0           // For timing spelling mode
    private var spellingLetterDuration: Double = 0        // Duration per letter
    // Store segment durations keyed by word
    private var wordDurationMap: [String: Double] = [:]   // Map word to its duration
    // ============================================================
    
    // --- IBOutlets ---
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var player2: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    //Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LocalVideoAvatarViewController loaded")
        
        setupUI()
        setupVideoPlayer()
        setupWebView()
        
        displayLink = CADisplayLink(target: self, selector: #selector(checkVideoTime))
        displayLink?.add(to: .main, forMode: .default)
        
        webView.configuration.userContentController.add(self, name: "avatarDone")
        playerContainer.layer.cornerRadius = 25
        outerView.layer.cornerRadius = 25
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .allButUpsideDown
        }
    }
    
    @objc func checkVideoTime() {
        guard let player = playerViewController?.player else { return }
        guard !glossEvents.isEmpty else { return }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        
        // Update progressive caption based on video time
        updateProgressiveCaption(for: currentTime)
        
        // Trigger ALL events whose time has passed
        while let nextEvent = glossEvents.first,
              currentTime >= nextEvent.time {
            
            // Check if this word needs spelling mode
            let word = nextEvent.gloss.uppercased()
            let existsInDB = DatabaseManager.shared.getAnimationSmart(for: word.lowercased()) != nil
            
            // Get duration from the map
            let duration = wordDurationMap[word.lowercased()] ?? 0.5
            
            if !existsInDB {
                // Word needs spelling - setup spelling mode with timing
                setupSpellingMode(for: word, startTime: nextEvent.time, duration: duration)
            } else {
                // Word exists - add to caption normally
                addWordToCaption(word: word, isCompleteWord: true)
            }
            
            playGloss(nextEvent.gloss)
            glossEvents.removeFirst()
        }
    }
    
    private func setupSpellingMode(for word: String, startTime: Double, duration: Double) {
        isSpellingMode = true
        currentSpellingWord = word
        currentSpellingIndex = 0
        currentWordStartTime = startTime
        currentWordDuration = duration
        spellingLetterDuration = duration / Double(word.count)
        
        // Add space before first letter if needed
        if needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }
    }
    
    private func updateProgressiveCaption(for currentTime: Double) {
        // Handle spelling mode letter timing
        if isSpellingMode && currentSpellingIndex < currentSpellingWord.count {
            let letterIndex = currentSpellingIndex
            let letterStartTime = currentWordStartTime + (Double(letterIndex) * spellingLetterDuration)
            
            if currentTime >= letterStartTime && letterIndex == currentSpellingIndex {
                // Time to add next letter
                let letter = String(currentSpellingWord[currentSpellingWord.index(currentSpellingWord.startIndex, offsetBy: letterIndex)])
                
                let oldLength = accumulatedCaption.count
                accumulatedCaption += letter
                
                let highlightRange = NSRange(location: oldLength, length: 1)
                updateCaptionDisplay(highlightRange: highlightRange)
                
                currentSpellingIndex += 1
                
                // Check if word spelling is complete
                if currentSpellingIndex >= currentSpellingWord.count {
                    isSpellingMode = false
                    needsSpaceBeforeNext = true
                    currentSpellingWord = ""
                    currentSpellingIndex = 0
                }
            }
        }
    }
    
    private func addWordToCaption(word: String, isCompleteWord: Bool) {
        if needsSpaceBeforeNext && !accumulatedCaption.isEmpty {
            accumulatedCaption += " "
            needsSpaceBeforeNext = false
        }
        
        let oldLength = accumulatedCaption.count
        accumulatedCaption += word
        
        let highlightRange = NSRange(location: oldLength, length: word.count)
        updateCaptionDisplay(highlightRange: highlightRange)
        
        needsSpaceBeforeNext = true
    }
    
    private func updateCaptionDisplay(highlightRange: NSRange) {
        let attributedString = NSMutableAttributedString(string: accumulatedCaption)
        
        // Set default color to black for entire text
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.black,
                                      range: NSRange(location: 0, length: accumulatedCaption.count))
        
        // Highlight the current word/letter in blue
        if highlightRange.location + highlightRange.length <= accumulatedCaption.count {
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.systemBlue,
                                          range: highlightRange)
        }
        
        captionLabel.attributedText = attributedString
        
        // Check if scrolling is needed
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("SCREEN TOUCHED")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let playerVC = playerViewController {
            playerVC.view.frame = playerContainer.bounds
        }
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerViewController?.player?.pause()
        stopScrolling()
    }
    
    func setupUI() {
        print("Setting up UI")
        view.backgroundColor = .white
        playerContainer.backgroundColor = .black
        webView.backgroundColor = .clear
        webView.isHidden = false
        
        captionLabel.text = ""
        captionLabel.layer.cornerRadius = 20
        captionLabel.clipsToBounds = true
        captionLabel.textAlignment = .left
        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byClipping
        captionLabel.adjustsFontSizeToFitWidth = false
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        captionLabel.text = "Preparing..."
        print("PLAY BUTTON CLICKED")
        
        guard let url = selectedVideoURL else { return }
        
        playButton.isHidden = true
        
        extractAudio(from: url)
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        stopScrolling()
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupVideoPlayer() {
        guard let videoURL = selectedVideoURL else {
            print("No video URL received!")
            showError("No video selected. Please go back and choose a video.")
            return
        }
        print("Video URL: \(videoURL.path)")
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("Video file does not exist at path: \(videoURL.path)")
            showError("Video file not found. Please select again.")
            return
        }
        let player = AVPlayer(url: videoURL)
        player.pause()
        player.seek(to: .zero)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.updatesNowPlayingInfoCenter = false
        playerViewController?.view.frame = playerContainer.bounds
        playerViewController?.showsPlaybackControls = false
        playerViewController?.videoGravity = .resizeAspect
        
        if let playerVC = playerViewController {
            addChild(playerVC)
            playerContainer.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)
            playerVC.view.isUserInteractionEnabled = false
            playerContainer.bringSubviewToFront(playButton)
            playerContainer.bringSubviewToFront(closeButton)
            print("Player view controller added to container")
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        player.currentItem?.addObserver(self,
                                        forKeyPath: "status",
                                        options: [.new, .initial],
                                        context: nil)
        print("Video playback started")
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                              of object: Any?,
                              change: [NSKeyValueChangeKey : Any]?,
                              context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("Player item is ready to play")
                case .failed:
                    print("Player item failed: \(item.error?.localizedDescription ?? "unknown error")")
                    showError("Failed to load video")
                case .unknown:
                    print("Player item status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            print("Error: \(message)")
            
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })
            
            self.present(alert, animated: true)
        }
    }
    
    @objc func videoDidEnd() {
        guard let url = selectedVideoURL else { return }
        
        let videoItem = VideoItem(
            id: url.lastPathComponent,
            title: url.lastPathComponent,
            thumbnail: "photo1",
            videoPath: url.path,
            duration: 0,
            createdAt: Date()
        )
        
        HistoryManager.shared.addVideo(videoItem)
        stopScrolling()
    }
    
    func stopVideo() {
        playButton.isHidden = false
    }
    
    @IBAction func backButtonTapped(_ senderx: Any) {
        print("Back button tapped")
        stopScrolling()
        dismiss(animated: true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func extractAudio(from url: URL) {
        let asset = AVURLAsset(url: url)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            print("Failed to create export session")
            return
        }
        
        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio.m4a")
        
        try? FileManager.default.removeItem(at: audioURL)
        
        Task {
            do {
                try await exportSession.export(to: audioURL, as: .m4a)
                print("Audio extracted successfully")
                await MainActor.run {
                    self.speechToText(audioURL: audioURL)
                }
            } catch {
                print("Export failed:", error)
            }
        }
    }
    
    func speechToText(audioURL: URL) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                print("Speech permission denied")
                DispatchQueue.main.async {
                    self.captionLabel.text = "Speech permission denied"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.captionLabel.text = "⏳ Recognizing..."
                self.resetCaptionBuilding()
                self.captionSegments = []
                self.captionWords = []
                self.currentCaptionIndex = 0
                self.glossEvents = []
                self.wordDurationMap = [:]  // Reset duration map
            }
            
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            
            self.recognitionRequest = SFSpeechURLRecognitionRequest(url: audioURL)
            guard let recognitionRequest = self.recognitionRequest else {
                print("Failed to create recognition request")
                return
            }
            recognitionRequest.requiresOnDeviceRecognition = false
            recognitionRequest.shouldReportPartialResults = false
            
            self.recognitionTask = self.speechRecognizer?.recognitionTask(
                with: recognitionRequest
            ) { result, error in
                
                if let error = error {
                    print("Recognition error: \(error)")
                    DispatchQueue.main.async {
                        self.captionLabel.text = "Recognition failed"
                    }
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                print("FULL TEXT:", result.bestTranscription.formattedString)
                let segments = result.bestTranscription.segments
                
                print("Total segments: \(segments.count)")
                for seg in segments {
                    print("Word: '\(seg.substring)' | Start: \(seg.timestamp)s | Duration: \(seg.duration)s")
                    // Store duration for each word (lowercased for lookup)
                    self.wordDurationMap[seg.substring.lowercased()] = seg.duration
                }
                
                DispatchQueue.main.async {
                    self.captionSegments = segments
                    self.captionWords = segments.map { $0.substring }
                    self.currentCaptionIndex = 0
                    self.captionLabel.text = ""
                    
                    self.glossEvents = self.glossProcessor.extractGlossTimeline(from: segments)
                    print("Gloss timeline: \(self.glossEvents)")
                    
                    self.playerViewController?.player?.seek(to: .zero)
                    self.playerViewController?.player?.play()
                }
            }
        }
    }
    
    private func resetCaptionBuilding() {
        stopScrolling()
        accumulatedCaption = ""
        isSpellingMode = false
        currentSpellingWord = ""
        currentSpellingIndex = 0
        needsSpaceBeforeNext = false
        currentWordStartTime = 0
        currentWordDuration = 0
        spellingLetterDuration = 0
        captionLabel.attributedText = nil
    }
    
    deinit {
        print("LocalVideoAvatarViewController deinit")
        displayLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
        stopScrolling()
        
        playerViewController?.player?.currentItem?.removeObserver(self, forKeyPath: "status")
        
        if let videoURL = selectedVideoURL,
           videoURL.path.contains("TemporaryDirectory") {
            try? FileManager.default.removeItem(at: videoURL)
            print("Temporary video file deleted")
        }
    }
}
