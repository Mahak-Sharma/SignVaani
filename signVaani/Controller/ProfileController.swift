//profile controller : //
//  ViewController.swift
//  SignVaaniProfile
//
//  Created by Anushka on 03/02/26.
//

import UIKit
//text field delegate is used to manipulate the text present in the text field (used in username text field, which will be hidden.
//avatar selection delegate : this is a custom protocol used to set the user pfp by selecting from the given pre loaded images
class ProfileController: UIViewController,UITextFieldDelegate, AvatarSelectionDelegate{
    //outlets created for username, email and profile picture
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    //this is separately made for username change, because, the user can change their name, by just clickig on the username, (or long pressing it?), then a keyboard will come up on the screen, from where they can change their name directly.
    //does inline changes by making it an editable text field.
    let nameField = UITextField()
    
    //no need for separate email text field, since we are not making the user change it everytime once the user has created their id.
    
//    let emailField = UITextField()
    
    //for edit icon to be displayed to change the pfp
    let editIcon = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // NAME SETUP
        //to add interacion with the name label
        name.isUserInteractionEnabled = true
        //to make the text field hidden/invisible, these formatting are added
        nameField.borderStyle = .none
        nameField.isHidden = true
        //this controller will handle the editing done and then updating and returning the new value entered
        nameField.delegate = self
        //now to set the text field inside the label, so that it can become editable, we use addSubview
        name.addSubview(nameField)
        //equating the label font to text field font
        nameField.font = name.font
        
        //to ensure that, when the name label is tapped, we add the editable functionality to it.
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(editName))
        
        //detects the tap done on the name label
        name.addGestureRecognizer(nameTap)

// -----------------NAME SET UP COMPLETED----------------

        
        // EDIT ICON SETUP
        //using sf symbol to set the eidt icon image
        editIcon.image = UIImage(systemName: "photo.fill")
        //rest formatting
        editIcon.tintColor = .black
        editIcon.backgroundColor = .none
        editIcon.layer.cornerRadius = 15
        //ensures that the icon stays inside the rounded corners
        editIcon.clipsToBounds = true
        editIcon.layer.borderWidth = 2
        
        //now, when the user taps on the icon, the pfp selection pop up will appear on the screen
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(openAvatarPopup))
        //recognizes the tap on the icon
        editIcon.addGestureRecognizer(tap)
        editIcon.isUserInteractionEnabled = true

        //adds interaction to the user pfp
        profileImage.isUserInteractionEnabled = true
        //puts the edit icon inside the pfp
        profileImage.addSubview(editIcon)
        profileImage.clipsToBounds = false

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        _ = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
    }
    
    // TO SET THE EDIT ICON TO THE BOTTOM RIGHT OF THE USER PFP
    override func viewDidLayoutSubviews() {
        //after the layout is finalized, this will run, as now the sizes and positions are known
        super.viewDidLayoutSubviews()
        
        //if the profile pic is squared, it will display it as a circle for cleaner UI
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
        
        //icon size set to 30x30 px
        let size: CGFloat = 20
        //now to set the icon at the bottom right of the pfp, we create a rectangular frame
        editIcon.frame = CGRect(
            x: profileImage.bounds.width - size - 4,
            y: profileImage.bounds.height - size - 4,
            width: size,
            height: size
        )
        
        editIcon.layer.cornerRadius = size / 2
        editIcon.clipsToBounds = true
        //bring icon to front to ensure that the icon is not hidden behind the views
        profileImage.bringSubviewToFront(editIcon)
        //temp debug print to check
        print(editIcon.frame)
        
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
        view.layer.insertSublayer(gradient, at: 0)}
    

    //TO EDIT NAME WHEN USER CLICKS ON THE NAME
    @objc func editName() {
        nameField.text = name.text
        //the hidden text field becomes visible
        nameField.isHidden = false
        //show keyboard on the screen
        nameField.becomeFirstResponder()
    }
    
    //when the user clicks on returnon keyboard, this function will work
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //if the edits are done in the name text field, then it will work
        if textField == nameField {
                name.text = textField.text
                name.isHidden = false
            }

        //after the updates are done, the text field will again become hidden and the keyboard will be off the screen
            textField.isHidden = true
            textField.resignFirstResponder()
        //confirms that the event was done.
            return true
    }
    
       // when the user taps on the edit icon, the list of pre loaded pfp will appear
        @objc func openAvatarPopup() {

            //first load the main storyboard file to connect the profile controller to image view controller to connect the pop up to the screen.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            //creating instance of image view controller, so that the user can perform the given functionality in this screen.
            let vc = storyboard.instantiateViewController(
                        withIdentifier: "ImageViewController"
                     ) as! ImageViewController

            //after the instance is created, this now lets the profile controller to be set as the delegate for image view controller
            //so whatever the action performed in the image view controller, it will send its output to profile controller
            vc.delegate = self
            //this will display the pop up in bottom sheet style
            vc.modalPresentationStyle = .pageSheet

            //controls the pop up behaviour and size
            if let sheet = vc.sheetPresentationController {
                //let pop up occupy half of the screen
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            //show pop up
            present(vc, animated: true)
        }

        //when the user selects the pfp
        func didSelectAvatar(image: UIImage) {
            //updates the user pfp
            profileImage.image = image
        }

    @IBAction func closeTapped(_ sender: UIButton) {
        if let nav = navigationController {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
    }
}
