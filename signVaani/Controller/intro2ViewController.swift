//
//  intro2ViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit
import AVFoundation
import AVKit

class intro2ViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var skipButton: UIButton!
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!

    override func viewDidLoad() {
            super.viewDidLoad()

            videoView.layer.cornerRadius = 25
            videoView.clipsToBounds = true

            //playVideo()
        }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            if player == nil {
                playVideo()
            }
        }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    func playVideo() {
        guard let path = Bundle.main.path(forResource: "introVaani2", ofType: "mp4") else {
            print("introVaani2.mp4 not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        player.play()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
    
    @objc func videoDidFinishPlaying() {
        // Segue to intro3 in storyboard
        performSegue(withIdentifier: "goToIntro3", sender: self)
    }
    
    @IBAction func skipTapped(_ sender: UIButton) {
        // Segue to signup in storyboard
        performSegue(withIdentifier: "skipToSignup", sender: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
