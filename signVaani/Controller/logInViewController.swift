//
//  logInViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit

class logInViewController: UIViewController {

    @IBOutlet weak var bigView: UIView!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var googleView: UIView!
    @IBOutlet weak var appleView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        bigView.layer.cornerRadius = 20
        emailView.layer.cornerRadius = 12
        passwordView.layer.cornerRadius = 12
        googleView.layer.cornerRadius = 20
        appleView.layer.cornerRadius = 20
    }
    
    @IBAction func signup(_ sender: UIButton) {
      
    }
}
