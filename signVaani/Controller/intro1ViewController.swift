
//
//  intro2ViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//


import UIKit
import AVFoundation

class intro1ViewController: UIViewController {
    
    @IBOutlet weak var videoView: UIView!
    
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
    
    // MARK: - Video Setup
    private func setupVideo() {
        cleanupVideo()
        
        guard let path = Bundle.main.path(forResource: "introVaani1", ofType: "mp4") else {
            print("❌ introVaani1.mp4 not found")
            showVideoPlaceholder()
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
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
    
    // MARK: - ✅ FIXED: Stop at last frame
    @objc private func videoDidFinishPlaying() {
        print("📹 Video finished")
        isVideoPlaying = false
        
        guard let player = player,
              let duration = player.currentItem?.duration else { return }
        
        // Pause playback
        player.pause()
        
        // Move to exact last frame
        player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func showVideoPlaceholder() {
        let label = UILabel()
        label.text = "Video not found\nAdd introVaani1.mp4"
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
    
    private func navigateToNextScreen() {
        if let nextVC = storyboard?.instantiateViewController(withIdentifier: "intro2ViewController") {
            navigationController?.pushViewController(nextVC, animated: true)
        } else {
            performSegue(withIdentifier: "toIntro2", sender: nil)
        }
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
        print("🗑️ intro1ViewController deinit")
    }
}
