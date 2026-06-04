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

    var incomingVideoURL: URL?

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

    // Playback Controls
    var playbackControlsView: UIVisualEffectView?
    var restartButton: UIButton?
    var playPauseButton: UIButton?

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
}
