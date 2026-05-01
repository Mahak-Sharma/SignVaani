//  HomeViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 25/03/26.
import UIKit
import AVFoundation
class HomeViewController: UIViewController {
    
    @IBOutlet weak var bigView: UIView!
    @IBOutlet weak var videoimageView: UIView!
    @IBOutlet weak var audioimageView: UIView!
    @IBOutlet weak var audioImageView: UIView!
    @IBOutlet weak var videoImageView: UIView!
//    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    
    //Video container
    @IBOutlet weak var namasteVideo: UIView!
    //Player properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI Styling
        bigView.layer.cornerRadius = 25
        videoImageView.layer.cornerRadius = 32
        audioImageView.layer.cornerRadius = 32
       
        videoimageView.layer.cornerRadius = 25
        audioimageView.layer.cornerRadius = 25
        audioImageView.bringSubviewToFront(audioButton)
        videoImageView.bringSubviewToFront(videoButton)
        setupVideo()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsUpdateOfSupportedInterfaceOrientations()
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // FIX: Bring buttons to front properly
               audioImageView.bringSubviewToFront(audioButton)
               videoImageView.bringSubviewToFront(videoButton)
        
               // ALTERNATIVE FIX: Make sure buttons are not hidden
               audioButton.isHidden = false
               videoButton.isHidden = false
               audioButton.isUserInteractionEnabled = true
               videoButton.isUserInteractionEnabled = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Remove old gradient (avoid stacking)
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
        // Ensure video layer resizes correctly
        playerLayer?.frame = namasteVideo.bounds
    }
    
    //for potraitOnly
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    //Video Setup
    func setupVideo() {
        //Remove old "played once" logic completely
        guard let path = Bundle.main.path(forResource: "videoHome", ofType: "mp4") else {
            print("videoHome.mp4 not found")
            return
        }
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = namasteVideo.bounds
        
        // Remove old layers
        namasteVideo.layer.sublayers?.filter { $0 is AVPlayerLayer }.forEach { $0.removeFromSuperlayer() }
        
        if let playerLayer = playerLayer {
            namasteVideo.layer.addSublayer(playerLayer)
        }
        
        namasteVideo.isHidden = false  // video dikhao
        
        player?.play()
    }
    //Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
