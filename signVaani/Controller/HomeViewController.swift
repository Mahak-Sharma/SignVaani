//
//  HomeViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 25/03/26.
//
import UIKit
import AVFoundation

class HomeViewController: UIViewController {

    @IBOutlet weak var bigView: UIView!
    @IBOutlet weak var videoimageView: UIView!
    @IBOutlet weak var audioimageView: UIView!

    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var profil: UIButton!
    @IBOutlet weak var profileImage: UIButton!
    @IBOutlet weak var audioImageView: UIView!
    @IBOutlet weak var videoImageView: UIView!
    @IBOutlet weak var namasteVideo: UIView!

    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupVideo()
        setupCardGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setNeedsUpdateOfSupportedInterfaceOrientations()

        navigationController?.setNavigationBarHidden(
            true,
            animated: animated
        )

        // LOAD SAVED AVATAR
        if let data = UserDefaults.standard.data(forKey: "userAvatar"),
           let savedImage = UIImage(data: data) {

            profileImageView.image = savedImage
            print("Avatar Loaded")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        setupGradient()

        profileImageView.layer.cornerRadius =
            profileImageView.frame.width / 2

        profileImageView.clipsToBounds = true

        playerLayer?.frame = namasteVideo.bounds
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func setupUI() {

        bigView.layer.cornerRadius = 25

        videoImageView.layer.cornerRadius = 32
        audioImageView.layer.cornerRadius = 32

        videoimageView.layer.cornerRadius = 25
        audioimageView.layer.cornerRadius = 25
    }

    func setupGradient() {

        view.layer.sublayers?.removeAll {
            $0.name == "gradientLayer"
        }

        let gradient = CAGradientLayer()

        gradient.name = "gradientLayer"

        gradient.colors = [
            UIColor(
                red: 234/255,
                green: 242/255,
                blue: 255/255,
                alpha: 1
            ).cgColor,

            UIColor(
                red: 163/255,
                green: 198/255,
                blue: 255/255,
                alpha: 1
            ).cgColor
        ]

        gradient.locations = [0.0, 0.7]

        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)

        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)

        gradient.frame = view.bounds

        view.layer.insertSublayer(
            gradient,
            at: 0
        )
    }

    func setupVideo() {

        guard let path =
                Bundle.main.path(
                    forResource: "videoHome",
                    ofType: "mp4"
                )
        else {
            print("videoHome.mp4 not found")
            return
        }

        let url = URL(fileURLWithPath: path)

        player = AVPlayer(url: url)

        playerLayer = AVPlayerLayer(player: player)

        playerLayer?.videoGravity = .resizeAspectFill

        playerLayer?.frame = namasteVideo.bounds

        namasteVideo.layer.sublayers?
            .filter { $0 is AVPlayerLayer }
            .forEach { $0.removeFromSuperlayer() }

        if let playerLayer = playerLayer {
            namasteVideo.layer.addSublayer(playerLayer)
        }

        namasteVideo.isHidden = false

        player?.play()
    }

    func setupCardGestures() {

        videoimageView.isUserInteractionEnabled = true
        audioimageView.isUserInteractionEnabled = true

        let videoTap = UITapGestureRecognizer(
            target: self,
            action: #selector(videoCardTapped)
        )

        videoimageView.addGestureRecognizer(videoTap)

        let audioTap = UITapGestureRecognizer(
            target: self,
            action: #selector(audioCardTapped)
        )

        audioimageView.addGestureRecognizer(audioTap)
    }

    @objc func videoCardTapped() {

        let storyboard = UIStoryboard(
            name: "Main",
            bundle: nil
        )

        let vc = storyboard.instantiateViewController(
            withIdentifier: "YourVideoViewControllerID"
        )

        navigationController?.pushViewController(
            vc,
            animated: true
        )
    }

    @objc func audioCardTapped() {

        let storyboard = UIStoryboard(
            name: "Main",
            bundle: nil
        )

        let vc = storyboard.instantiateViewController(
            withIdentifier: "YourAudioViewControllerID"
        )

        navigationController?.pushViewController(
            vc,
            animated: true
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
