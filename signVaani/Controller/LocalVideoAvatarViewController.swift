//  LocalVideoAvatarViewController.swift
import UIKit
import AVKit
import AVFoundation
import WebKit
import NaturalLanguage
import Speech
class LocalVideoAvatarViewController: UIViewController {
//    @IBOutlet weak var AddplaylistButton: UIButton!
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
    // Receive video from UploadOptionsViewController
    var selectedVideoURL: URL? {
        //whenever video is select this will run and call the exteract video so that (audio extract hogyi waha se)
        didSet {
            print("Video URL received: \(selectedVideoURL?.path ?? "nil")")
        }
    }
    // Speech recognition properties
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))//this creates a speech recognizer for english
    //let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest: SFSpeechURLRecognitionRequest?// this stores the sudiofile request
    var recognitionTask: SFSpeechRecognitionTask?//this performs the recognition
    //IBOutlets
    
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var player2: UIView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var playerContainer: UIView!// this view hold the video player
    @IBOutlet weak var webView: WKWebView!//this displays the sign languagevatar HTML page
    //close button
    @IBOutlet weak var closeButton: UIButton! //playButtonUI
    @IBOutlet weak var playButton: UIButton!
    //Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("LocalVideoAvatarViewController loaded")
        //these all function intialize the screen
        setupUI()
        setupVideoPlayer()
        setupWebView()
        // Sync avatar with video time ********
        displayLink = CADisplayLink(target: self,selector: #selector(checkVideoTime))// call checkVideoTime()every frame
        displayLink?.add(to: .main, forMode: .default) //it runs continously
        //this allows JavaScript inside HTML to send messages to Swift.
        webView.configuration.userContentController.add(self,name: "avatarDone")
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
//    //video time checking function-synchronizes avatar animation with video time
//    @objc func checkVideoTime() {
//        guard let player = playerViewController?.player else { return }
//        guard let nextEvent = glossEvents.first else { return }
//        if isPlayingGloss { return }  // ← this guard is correct
//
//        let currentTime = CMTimeGetSeconds(player.currentTime())
//        //to display captionst
//        updateCaption(for: currentTime)
//        if currentTime >= nextEvent.time {
//            playGloss(nextEvent.gloss)
//            glossEvents.removeFirst()
//        }
//    }
    @objc func checkVideoTime() {
        guard let player = playerViewController?.player else { return }
        guard !glossEvents.isEmpty else { return }

        let currentTime = CMTimeGetSeconds(player.currentTime())

        updateCaption(for: currentTime)

        // Trigger ALL events whose time has passed
        while let nextEvent = glossEvents.first,
              currentTime >= nextEvent.time {
            
            playGloss(nextEvent.gloss)
            glossEvents.removeFirst()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("SCREEN TOUCHED")
    }
    //Runs every time the screen becomes visible. dusri screen se ispe anna par for example playluist sheet to video screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("View appeared")
        // Double-check webview after view appears
        if webView.isHidden {
            print("WebView is hidden, attempting to reload")
            setupWebView()
        }
        //Reset video
        playerViewController?.player?.pause()
        playerViewController?.player?.seek(to: .zero)
    }
    //video fill the container view mtlb jb device rotate hota hai incase then it will update in player also it will check
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let playerVC = playerViewController {
            playerVC.view.frame = playerContainer.bounds
        }
        // Remove duplicate gradient layers
        view.layer.sublayers?.removeAll(where: { $0.name == "gradientLayer" })

        // Create gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 234/255, green: 242/255, blue: 255/255, alpha: 1).cgColor,
            UIColor(red: 163/255, green: 198/255, blue: 255/255, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.7]  // Removed extra 1.0 location
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)

    }
  
    // Stops video when leaving the screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerViewController?.player?.pause()
    }
    func setupUI() {
        print("Setting up UI")
        view.backgroundColor = .white 
        playerContainer.backgroundColor = .black
        webView.backgroundColor = .clear
        webView.isHidden = false

        // Caption label styling
        captionLabel.text = ""

        captionLabel.layer.cornerRadius = 20
        captionLabel.clipsToBounds = true
    }
    //playButton
//    @IBAction func playButtonTapped(_ sender: Any) {
//        captionLabel.text = "Playing video..."
//            print("PLAY BUTTON CLICKED")
//        
//        guard let player = playerViewController?.player else { return }
//        guard let url = selectedVideoURL else { return }
//            player.seek(to: .zero)   // start from beginning
//            player.play()//start
//            playButton.isHidden = true//disapper
//        // etracting audio here otherwise vedio start withay tapping thg the play button
//                extractAudio(from: url)
//    }
    @IBAction func playButtonTapped(_ sender: Any) {
        captionLabel.text = "Preparing..."
        print("PLAY BUTTON CLICKED")

        guard let url = selectedVideoURL else { return }

        playButton.isHidden = true

        // ❗ DO NOT PLAY VIDEO HERE
        // Only start processing
        extractAudio(from: url)
    }
    //after tapping close button lands on hoe screen
    @IBAction func closeButtonTapped(_ sender: UIButton) {
            self.dismiss(animated: true, completion: nil)
        }
    func setupVideoPlayer() { //creates the video player system.
        guard let videoURL = selectedVideoURL else {
            print("No video URL received!")
            showError("No video selected. Please go back and choose a video.")
            return
        }
        print("Video URL: \(videoURL.path)")
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print(" Video file does not exist at path: \(videoURL.path)")
            showError("Video file not found. Please select again.")
            return
        }
        let player = AVPlayer(url: videoURL)//his object handles playback.
        player.pause()
        player.seek(to: .zero)
        playerViewController = AVPlayerViewController()//displays video
        playerViewController?.player = player
        playerViewController?.updatesNowPlayingInfoCenter = false // meri video tyar hai chalne ke liye
        playerViewController?.view.frame = playerContainer.bounds
        playerViewController?.showsPlaybackControls = false//custom controls maintain aspect ratio
        playerViewController?.videoGravity = .resizeAspect
        //playerViewController?.entersFullScreenWhenPlaybackBegins = false
        //playerViewController?.exitsFullScreenWhenPlaybackEnds = false
        if let playerVC = playerViewController {
            addChild(playerVC) //This embeds the player.
            playerContainer.addSubview(playerVC.view)
            playerVC.didMove(toParent: self)

            
            playerVC.view.isUserInteractionEnabled = false
//            // bring button above video
           /* playerContainer.bringSubviewToFront(AddplaylistButton)*/ //Ensures buttons appear above video.
            playerContainer.bringSubviewToFront(playButton)
            playerContainer.bringSubviewToFront(closeButton)

            print("Player view controller added to container")
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,//Detects when video ends.
            object: player.currentItem
        )
     // observe value i striggered vale automatically whenever status changes of video player item
        player.currentItem?.addObserver(self,
                                        forKeyPath: "status",
                                        options: [.new, .initial],
                                        context: nil)
        print("Video playback started")
    }
  //whenever the status of the video player changes, notify this controller
//watch changes in object properties
    // Add this new method to handle layout updates
    func updateLayoutForSize(_ size: CGSize) {
        let isLandscape = size.width > size.height
        
        playerContainer.translatesAutoresizingMaskIntoConstraints = true
        webView.translatesAutoresizingMaskIntoConstraints = true
        
        if isLandscape {
            let halfWidth = size.width / 2
            let availableHeight = size.height - view.safeAreaInsets.top
            
            player2.frame = CGRect(
                x: 0,
                y: view.safeAreaInsets.top,
                width: halfWidth,
                height: availableHeight
            )
            
            playerContainer.frame = CGRect(
                x: 0,
                y: 0,
                width: halfWidth,
                height: availableHeight
            )
            
            webView.frame = CGRect(
                x: halfWidth,
                y: view.safeAreaInsets.top,
                width: halfWidth,
                height: availableHeight
            )
            
            // AVPlayerLayer nahi - yeh use karo
            playerViewController?.view.frame = playerContainer.bounds
        }
        // Update player view to fill container
        if let playerVC = playerViewController {
            playerVC.view.frame = playerContainer.bounds
        }
        
        // Bring buttons to front
        playerContainer.bringSubviewToFront(playButton)
        playerContainer.bringSubviewToFront(closeButton)
        
        // Force layout update
        view.layoutIfNeeded()
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
    
    // for alert if incase video fails so this fucntion will show the alert popip
    func showError(_ message: String) {
        DispatchQueue.main.async {
            print("Error: \(message)")
            
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true) // when user press ok then this one code run
            })
            
            self.present(alert, animated: true)//diplay the alert
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
        }
    
    func stopVideo() {
        
       // playerViewController?.player?.pause()
        playButton.isHidden = false
    }

    //Navigation
    @IBAction func backButtonTapped(_ senderx: Any) {
        print("Back button tapped")
        dismiss(animated: true)
    }
    //Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    override var shouldAutorotate: Bool {
        return true
    }
    //Status Bar
    override var prefersStatusBarHidden: Bool {
        return false
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    // videoFile->AudioExtract->audio.mpfile->speechToText()
    func extractAudio(from url: URL) {
        let asset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession( //video ko process karke naya file banana video -> audio
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
            //presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("Failed to create export session")
            return
        }
        //<<<<<<here we decide where we have to save the audio in this we have in tem directory>>>>>//
        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("audio.m4a")
        // agar same name ki file phele se exist kar rhi hai usku delete kardete hai then new file save karte hai
        try? FileManager.default.removeItem(at: audioURL) //
        //background ma hoti hai yeh cheej audio because main thread pe karenge toh ui freeze hojayega
        //launches a new concureent task  this run off hte main thread automatically,keeping the Ui responsive during
        Task {
            do {
                // this is ios api usng for
                try await exportSession.export(to: audioURL, as: .m4a)
                print("Audio extracted successfully")
                await MainActor.run {
                    self.speechToText(audioURL: audioURL) // now my  audio file is ready i have to calll speech to text
                }
            } catch {
                print("Export failed:", error)
            }
        }
    }
    var currentIndex = 0
    var displayedWords: [String] = []

    func updateCaption(for currentTime: Double) {
        while currentIndex < captionSegments.count {
            let segment = captionSegments[currentIndex]

            if currentTime >= segment.timestamp {
                displayedWords.append(segment.substring)
                currentIndex += 1
            } else {
                break
            }
        }

        // Keep only last few words (like rolling caption)
        let lastWords = displayedWords.suffix(6).joined(separator: " ")

        DispatchQueue.main.async {
            self.captionLabel.text = lastWords
        }
    }
    //speech ->text->gloss->videoplay
    func speechToText(audioURL: URL) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                print("Speech permission denied")
                DispatchQueue.main.async {
                    self.captionLabel.text = "Speech permission denied"
                }
                return
            }
            
            // Clear all previous data
            DispatchQueue.main.async {
                self.captionLabel.text = "⏳ Recognizing..."
                self.captionSegments = []
                self.captionWords = []
                self.currentCaptionIndex = 0
                self.glossEvents = []
            }
            
            // Cancel any existing task
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            
            self.recognitionRequest = SFSpeechURLRecognitionRequest(url: audioURL)
            guard let recognitionRequest = self.recognitionRequest else {
                print("Failed to create recognition request")
                return
            }
            recognitionRequest.requiresOnDeviceRecognition = false
            
            // Wait for complete final result so all timestamps are accurate
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
                
                // Debug — verify timestamps in console
                print("Total segments: \(segments.count)")
                for seg in segments {
                    print("Word: '\(seg.substring)' | Start: \(seg.timestamp)s | Duration: \(seg.duration)s")
                }
                
                DispatchQueue.main.async {
                    // Store segments for checkVideoTime() caption sync
                    self.captionSegments = segments
                    
                    // Store original spoken words for sliding caption display
                    self.captionWords = segments.map { $0.substring }
                    self.currentCaptionIndex = 0
                    
                    // Clear recognizing placeholder
                    self.captionLabel.text = ""
                    
                    // Build gloss timeline for avatar
                    self.glossEvents = self.glossProcessor.extractGlossTimeline(from: segments)
                    print("Gloss timeline: \(self.glossEvents)")
                    
                    // Start video only after everything is ready
                    self.playerViewController?.player?.seek(to: .zero)
                    self.playerViewController?.player?.play()
                }
            }
        }
    }
       
    //Cleanup
    deinit {
        print("LocalVideoAvatarViewController deinit")
        displayLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
        
        playerViewController?.player?.currentItem?.removeObserver(self, forKeyPath: "status")
        
        if let videoURL = selectedVideoURL,
           videoURL.path.contains("TemporaryDirectory") {
            try? FileManager.default.removeItem(at: videoURL)
            print("Temporary video file deleted")
        }
    }
}
