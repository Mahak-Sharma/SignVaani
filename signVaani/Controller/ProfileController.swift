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

    @IBOutlet weak var email: UILabel!

    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var profileImage: UIImageView!

    //this is separately made for username change,
    //because the user can change their name
    //by clicking on the username
    //for edit icon to be displayed to change the pfp

    let editIcon = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // LOAD SAVED USER DATA

        let savedName =
            UserDefaults.standard.string(
                forKey: "userName"
            ) ?? "User"

        let savedGender =
            UserDefaults.standard.string(
                forKey: "userGender"
            ) ?? ""

        let savedDOB =
            UserDefaults.standard.string(
                forKey: "userDOB"
            ) ?? ""

        // SHOW SAVED NAME
        name.text = savedName

        // SHOW EXTRA INFO
        email.text = "\(savedGender) • \(savedDOB)"

        // Add this after your existing UserDefaults loading code
        if let data = UserDefaults.standard.data(forKey: "savedAvatar"),
           let savedImage = UIImage(data: data) {
            profileImage.image = savedImage
        } else {
            profileImage.image = UIImage(named: "defaultAvatar") // your placeholder
        }
        

        // EDIT ICON SETUP

        //using sf symbol to set edit icon image
        editIcon.image = UIImage(systemName: "photo.fill")

        //rest formatting
        editIcon.tintColor = .black

        editIcon.backgroundColor = .white

        editIcon.layer.cornerRadius = 15

        //ensures icon stays inside rounded corners
        editIcon.clipsToBounds = true

        editIcon.layer.borderWidth = 1

        //tap on edit icon opens avatar popup
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(openAvatarPopup)
        )

        //recognizes tap on icon
        editIcon.addGestureRecognizer(tap)

        editIcon.isUserInteractionEnabled = true

        //adds interaction to profile image
        profileImage.isUserInteractionEnabled = true

        //puts edit icon inside profile image
        profileImage.addSubview(editIcon)

        profileImage.clipsToBounds = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    // TO SET THE EDIT ICON TO THE BOTTOM RIGHT OF USER PFP

    override func viewDidLayoutSubviews() {

        //after layout finalized
        super.viewDidLayoutSubviews()

        //make profile image circular
        profileImage.layer.cornerRadius =
            profileImage.frame.height / 2

        //icon size
        let size: CGFloat = 20

        //position icon bottom right
        editIcon.frame = CGRect(
            x: profileImage.bounds.width - size - 4,
            y: profileImage.bounds.height - size - 4,
            width: size,
            height: size
        )

        editIcon.layer.cornerRadius = size / 2

        editIcon.clipsToBounds = true

        //bring icon to front
        profileImage.bringSubviewToFront(editIcon)

        //temp debug print
        print(editIcon.frame)

        // Remove duplicate gradient layers
        view.layer.sublayers?.removeAll {
            $0.name == "gradientLayer"
        }

        // Create gradient
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

    
    //when user clicks return on keyboard
    // when user taps edit icon,
    // list of avatars appears

    @objc func openAvatarPopup() {

        //load storyboard
        let storyboard = UIStoryboard(
            name: "Main",
            bundle: nil
        )

        //instance of image view controller
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ImageViewController"
        ) as! ImageViewController

        //set delegate
        vc.delegate = self

        //display popup as bottom sheet
        vc.modalPresentationStyle = .pageSheet

        //popup behaviour and size
        if let sheet = vc.sheetPresentationController {

            //half screen popup
            sheet.detents = [.medium()]

            sheet.prefersGrabberVisible = true
        }

        //show popup
        present(vc, animated: true)
    }

    //when user selects avatar

    func didSelectAvatar(image: UIImage) {

        //update profile image
        profileImage.image = image
        // Save to UserDefaults
            if let data = image.pngData() {
                UserDefaults.standard.set(data, forKey: "savedAvatar")
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
