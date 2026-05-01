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
    //Speech Recognition Properties
    private let glossProcessor = GlossProcessor()
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var pendingSegments: [SFTranscriptionSegment] = []
    private var glossEvents: [GlossEvent] = []
    private var lastProcessedSegment = 0
    private var isListening = false          // mic toggle state track karta hai
    private var isPlayingGloss = false       // gloss queue guard
    private var captionWords: [String] = []
    private var currentIndex = 0
    // it calls when screen load first time
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        captionView.layer.cornerRadius = 20
        // AvatarWebViewProtocol se — index.html load karta hai
        setupWebView()
        // JavaScript "avatarDone" message handle karne ke liye
        webView.configuration.userContentController.add(self, name: "avatarDone")
        setupMicButton()
        setupCaptionLabel()
  recordView.layer.cornerRadius = 6
        outerView.layer.cornerRadius = 25
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        _ = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
    }
    // it is call when layout changes
    override func viewDidLayoutSubviews() {
       
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
    
    // MicButton setup
    private func setupMicButton() {
        micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        micButton.tintColor = .white
        
        micButton.layer.cornerRadius = micButton.frame.height / 2
        micButton.clipsToBounds = true
        
    }
    
    // in this caption jo user bolenge bo ayega
    private func setupCaptionLabel() {
        captionLabel.text = "Tap mic to start"
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 1              // single line
        captionLabel.lineBreakMode = .byClipping
    }
    
    //Mic Button Action
    @IBAction func micButtonTapped(_ sender: UIButton) {
        if isListening { // agar bo already listen kar rha hai then stopspeech function ko call karenge
            stopSpeechRecognition()
        } else { // warna permision ke lenege and start karenge
            requestPermissionsAndStart()
        }
    }
    
    //Permission Request
    // Pehle Speech permission → phir Microphone permission → phir recognition start
    private func requestPermissionsAndStart() {
        // show the ios pop up for speech reco
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
            // if speech permission is granted thisline runs
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { // -----If permission is granted so startspeechreco is called here
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
    //Speech Recognition Start- it seetups and start p the speech recognition process
    //Final result wait karna
    private func startSpeechRecognition() {
        //fresh start before any recording
        lastProcessedSegment = 0
        glossEvents.removeAll()
        pendingSegments.removeAll()
        isPlayingGloss = false
        
        recognitionTask?.cancel() //cancel only if it exist
        recognitionTask = nil //set to nil fully relaease from memory
        
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
        
        //On-device recognition — faster + more accurate for Indian accent
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
            
            //Sirf FINAL result lo partial ignore karo
            if result.isFinal {
                print("Final result:", result.bestTranscription.formattedString)
                
                let segments = result.bestTranscription.segments
                self.pendingSegments = segments  // replace karo, append nahi
                self.lastProcessedSegment = segments.count
                
                DispatchQueue.main.async {
                    self.captionLabel.text = "Processing..."
                }
            } else {
                // Partial result — sirf log karo, process mat karo
                print("Partial:", result.bestTranscription.formattedString)
            }
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            
            DispatchQueue.main.async {
                //Mic becomes STOP button
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
                
                //Caption text
                self.captionLabel.text = "Listening..."
            }
            
            print("Speech recognition started")
        } catch {
            print("Audio engine failed:", error)
        }
    }
    
    //Stop mein 2 sec wait — final result aane do
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        isListening = false
        
        DispatchQueue.main.async {
            //Back to mic button
            self.micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
           
            //Record view reset
            self.recordView.layer.sublayers?.filter { $0.name == "pulse" }.forEach { $0.removeFromSuperlayer() }
            self.recordView.backgroundColor = .lightGray
            
            //Processing text
            self.captionLabel.text = "⏳ Processing..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.interpretAndShowCaption()
        }
    }
    //Interpret & Show Caption
    private func interpretAndShowCaption() {
        guard !pendingSegments.isEmpty else {
            captionLabel.text = "Tap mic to start"
            return
        }
        
        let segmentsToProcess = pendingSegments
        pendingSegments.removeAll()
        
        //ORIGINAL spoken words (NOT gloss)
        captionWords = segmentsToProcess.map { $0.substring }
        currentIndex = 0
        
        // Clear label
        captionLabel.text = ""
        
        // Gloss for avatar (unchanged)
        let events = glossProcessor.extractGlossTimeline(from: segmentsToProcess)
        glossEvents.append(contentsOf: events)
        
        if !isPlayingGloss {
            playGlossQueue()
        }
    }
    //Gloss Queue Player
    // Ek ek karke gloss avatar ko bhejta hai, 1.5 sec delay ke saath
    private func playGlossQueue() {
        
        guard !glossEvents.isEmpty else {
            isPlayingGloss = false
            return
        }
        
        isPlayingGloss = true
        
        let event = glossEvents.removeFirst()
        
        //Show ORIGINAL word (not gloss)
        if currentIndex < captionWords.count {
            let word = captionWords[currentIndex]
            currentIndex += 1
            
            DispatchQueue.main.async {
                let maxLength = 40
                
                let newText = (self.captionLabel.text ?? "") + " " + word
                
                //Keep only last part (single line sliding)
                let finalText = newText.count > maxLength
                ? String(newText.suffix(maxLength))
                : newText
                
                self.captionLabel.text = finalText.trimmingCharacters(in: .whitespaces)
            }
        }
        // Avatar still plays gloss
        playGloss(event.gloss)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.playGlossQueue()
        }
    }
    
    //Avatar Communication
    // JavaScript function call karke avatar ko gloss bhejta hai
    private func playGloss(_ gloss: String) {
        
        let normalized = gloss
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let json = DatabaseManager.shared.getAnimationSmart(for: normalized) else {
                print("No animation found for:", normalized)
                return
            }
        print("Normalized word:", normalized)
        
        if let data = json.data(using: .utf8),
           let encoded = try? JSONSerialization.jsonObject(with: data),
           let safeData = try? JSONSerialization.data(withJSONObject: encoded),
           let safeString = String(data: safeData, encoding: .utf8) {

            let js = "playGlossFromJSON(\(safeString))"
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("JS Error:", error)
                } else {
                    print("Playing from DB:", gloss)
                }
            }
        }
        if DatabaseManager.shared.getAnimationSmart(for: gloss) != nil {
            print("Found in DB:", gloss)
        } else {
            print("NOT FOUND in DB:", gloss)
        }
    }
}

//AvatarWebViewProtocol
// setupWebView() aur loadFallbackAvatar() yahan se aate hain (homeWebView.swift)
//WKNavigationDelegate
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

//WKScriptMessageHandler
extension LiveViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "avatarDone" {
            print("Avatar animation complete")
            // Play next gloss only after current one finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.playGlossQueue()
            }
        }
    }
}
