
//
//  intro2ViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit
import AVFoundation

class intro3ViewController: UIViewController {
 
    @IBOutlet weak var videoView: UIView!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isVideoPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayer()
        videoView.clipsToBounds = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateVideoLayerFrame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let player = player, !isVideoPlaying {
            player.play()
            isVideoPlaying = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        isVideoPlaying = false
    }
    
    // MARK: - Setup
    
    private func setupVideoPlayer() {
        cleanupVideo()
        
        guard let url = Bundle.main.url(forResource: "introVaani3", withExtension: "mp4") else {
            print("❌ introVaani3.mp4 not found")
            showPlaceholder()
            return
        }
        
        createPlayer(with: url)
    }
    
    private func createPlayer(with url: URL) {
        print("✅ Loading video:", url)
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        
        // ✅ FIX: fill like intro2
        playerLayer?.videoGravity = .resizeAspectFill
        
        playerLayer?.backgroundColor = UIColor.black.cgColor
        playerLayer?.frame = videoView.bounds
        
        videoView.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })
        
        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }
        
        player?.play()
        isVideoPlaying = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        print("📹 Video started")
    }
    
    private func updateVideoLayerFrame() {
        guard let playerLayer = playerLayer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = videoView.bounds
        CATransaction.commit()
    }
    
    // MARK: - Stop at last frame + navigate
    
    @objc private func videoDidFinishPlaying() {
        print("📹 Video finished")
        isVideoPlaying = false
        
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        player.pause()
        player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.completeIntroAndNavigateToHome()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func next(_ sender: Any) {
        pauseVideo()
        completeIntroAndNavigateToHome()
    }
    
    @IBAction func skipButtonTapped(_ sender: Any) {
        pauseVideo()
        completeIntroAndNavigateToHome()
    }
    
    // MARK: - Navigation
    
    private func completeIntroAndNavigateToHome() {
        UserDefaults.standard.set(true, forKey: "hasCompletedIntroFlow")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        let nav = UINavigationController(rootViewController: homeVC)
        
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first {
            
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Helpers
    
    private func showPlaceholder() {
        let label = UILabel()
        label.text = "Video not found\nAdd introVaani3.mp4"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        videoView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: videoView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: videoView.centerYAnchor)
        ])
    }
    
    private func cleanupVideo() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    // MARK: - Controls
    
    func pauseVideo() {
        player?.pause()
        isVideoPlaying = false
    }
    
    func resumeVideo() {
        player?.play()
        isVideoPlaying = true
    }
    
    func replayVideo() {
        player?.seek(to: .zero)
        player?.play()
        isVideoPlaying = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupVideo()
        print("🗑️ intro3ViewController deinit")
    }
}
