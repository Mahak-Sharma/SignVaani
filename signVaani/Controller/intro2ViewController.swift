//
//  intro2ViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit
import AVFoundation

class intro2ViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var skip: UIButton!
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isVideoPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideo()
        videoView.layer.cornerRadius = 25
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
    
    // MARK: - SAME AS INTRO1
    
    private func setupVideo() {
        cleanupVideo()
        
        guard let path = Bundle.main.path(forResource: "introVaani2", ofType: "mp4") else {
            print("❌ introVaani2.mp4 not found")
            showVideoPlaceholder()
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = videoView.bounds
        playerLayer?.backgroundColor = UIColor.white.cgColor
        
        videoView.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })
        
        if let playerLayer = playerLayer {
            videoView.layer.addSublayer(playerLayer)
        }
        
        videoView.backgroundColor = .white
        
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
    
    // MARK: - SAME END BEHAVIOR
    
    @objc private func videoDidFinishPlaying() {
        print("📹 Video finished")
        isVideoPlaying = false
        
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        player.pause()
        player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
        
        // optional navigation (same pattern as intro1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.completeIntroAndNavigateToHome()
        }
    }
    
    // MARK: - Actions
    
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
    
    private func showVideoPlaceholder() {
        let label = UILabel()
        label.text = "Video not found\nAdd introVaani2.mp4"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
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
    
    func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
        isVideoPlaying = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupVideo()
        print("🗑️ intro2ViewController deinit")
    }
}
