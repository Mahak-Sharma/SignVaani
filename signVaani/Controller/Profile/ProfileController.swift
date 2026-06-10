//
//  ProfileController.swift
//  SignVaaniProfile
//
//  Created by Anushka on 03/02/26.
//

import UIKit

//text field delegate is used to manipulate the text present in the text field
//(used in username text field, which will be hidden.)

//avatar selection delegate : this is a custom protocol used to set
//the user pfp by selecting from the given pre loaded images

class ProfileController: UIViewController,
                         AvatarSelectionDelegate {

    //outlets created for username and profile picture
    @IBOutlet weak var outerView: UIView!
    
    @IBOutlet weak var card1: UIView!
    @IBOutlet weak var infoCard: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var innerView: UIView!

    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var profileImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        loadSavedProfile()
    }

    private func configureAppearance() {
        navigationItem.rightBarButtonItem = nil

        [card1, infoCard].forEach { card in
            card?.backgroundColor = .white.withAlphaComponent(0.55)
            card?.layer.cornerRadius = 16
            card?.clipsToBounds = true
        }

        outerView.backgroundColor = .clear
        innerView.backgroundColor = .clear
        innerView.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFill
        profileImage.clipsToBounds = true
        profileImage.isUserInteractionEnabled = false

        name.textColor = UIColor(
            red: 12/255,
            green: 56/255,
            blue: 136/255,
            alpha: 1
        )
    }

    private func loadSavedProfile() {
        let savedName =
            UserDefaults.standard.string(
                forKey: "userName"
            ) ?? "User"

        name.text = savedName
        userName.text = savedName
        navigationItem.title = "\(savedName)'s Profile"

        let savedAvatar =
            UserDefaults.standard.data(forKey: "userAvatar") ??
            UserDefaults.standard.data(forKey: "savedAvatar")

        if let data = savedAvatar,
           let savedImage = UIImage(data: data) {
            profileImage.image = savedImage
        } else {
            profileImage.image = UIImage(named: "3247bef7-b265-43c2-9220-77f64bcec0d4")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadSavedProfile()

        navigationController?.setNavigationBarHidden(
            false,
            animated: animated
        )

        _ = UIColor(
            red: 47/255,
            green: 74/255,
            blue: 107/255,
            alpha: 1
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        profileImage.layer.cornerRadius = profileImage.bounds.height / 2
        innerView.layer.cornerRadius = innerView.bounds.height / 2

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

        gradient.startPoint =
            CGPoint(x: 0.5, y: 0.0)

        gradient.endPoint =
            CGPoint(x: 0.5, y: 1.0)

        gradient.frame = view.bounds

        view.layer.insertSublayer(
            gradient,
            at: 0
        )
    }

    func didSelectAvatar(image: UIImage) {
        profileImage.image = image

        if let data = image.pngData() {
            UserDefaults.standard.set(data, forKey: "userAvatar")
        }
    }

    @IBAction func closeTapped(_ sender: UIButton) {

        if let nav = navigationController {

            nav.popViewController(animated: true)

        } else {

            dismiss(animated: true)
        }
    }
}
