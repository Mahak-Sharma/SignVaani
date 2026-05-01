//
//  PrivacyViewController.swift
//  signVaani
//
//  Created by Bhavya Agarwal on 07/02/26.
//

import UIKit

class PrivacyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)}
    @IBAction func deleteAccountButtonTapped(_ sender: UIButton) {
        //when the user clicks on delete account in privacy, this alert will pop up
        let alert = UIAlertController(
                title: "Do you want to delete your account?",
                message: "Deleting your account will permanently remove your profile and data.",
                preferredStyle: .alert
            )

        //cancel button created
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        //proceed button created
        //for now, we have not provided the further functionality when the user deletes the account.
            let proceedAction = UIAlertAction(title: "Proceed", style: .destructive, handler: nil)

        //buttons added to the alert
            alert.addAction(cancelAction)
            alert.addAction(proceedAction)

        //showing the alert on the screen.
            present(alert, animated: true)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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
}
