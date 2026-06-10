import UIKit
internal import WebKit
internal import Speech
import AVFoundation

class LiveViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var captionView: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    var incomingVideoURL: URL?
    var processingAlert: UIAlertController?

    // Speech Recognition
    let glossProcessor = GlossProcessor()
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    var pendingSegments: [SFTranscriptionSegment] = []

    // Gloss Playback
    var glossEvents: [GlossEvent] = []
    var originalGlossEvents: [GlossEvent] = []
    var lastPlayedGloss: String?
    var currentGlossQueue: [String] = []
    var currentQueueIndex: Int = 0

    // Spelling Mode
    var isSpellingMode: Bool = false
    var currentSpellingWord: String = ""
    var currentSpellingIndex: Int = 0

    // Caption
    var accumulatedCaption: String = ""
    var needsSpaceBeforeNext: Bool = false
    var scrollTimer: Timer?

    // State
    var lastProcessedSegment = 0
    var isListening = false
    var isAvatarAnimating = false
    var isAvatarPaused = false
    var hasProcessedIncomingVideo = false


    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        captionView.layer.cornerRadius = 20
        setupWebView()
        webView.configuration.userContentController.add(self, name: "avatarDone")
        setupMicButton()
        setupCaptionLabel()
      //  setupAvatarPlaybackControls()
        recordView.layer.cornerRadius = 6
        outerView.layer.cornerRadius = 25
        outerView.clipsToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let videoURL = incomingVideoURL, !hasProcessedIncomingVideo {
            hasProcessedIncomingVideo = true
            
            micButton.isHidden = true
            recordView.isHidden = true
            
            // Show processing dialog box
            let alert = UIAlertController(
                title: nil,
                message: "Processing video...",
                preferredStyle: .alert
            )
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            indicator.translatesAutoresizingMaskIntoConstraints = false
            alert.view.addSubview(indicator)
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
                indicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -16)
            ])
            self.processingAlert = alert
            present(alert, animated: true)
            
            captionLabel.text = "Extracting audio..."
            extractAndProcess(videoURL: videoURL)
        }
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

    @IBAction func micButtonTapped(_ sender: UIButton) {
        isListening ? stopSpeechRecognition() : requestPermissionsAndStart()
    }
    @IBAction func restartButtonTapped(_ sender: UIButton)
    {
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
    @IBAction func playPauseButtonTapped(_ sender: UIButton)
    {
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
