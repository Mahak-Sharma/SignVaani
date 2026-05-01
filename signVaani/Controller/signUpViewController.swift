//
//  signUpViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit

class signUpViewController: UIViewController {

    @IBOutlet weak var appleView: UIView!
    @IBOutlet weak var googleView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var userNameView: UIView!
    @IBOutlet weak var bigView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bigView.layer.cornerRadius = 20
        userNameView.layer.cornerRadius = 12
        emailView.layer.cornerRadius = 12
        passwordView.layer.cornerRadius = 12
        googleView.layer.cornerRadius = 20
        appleView.layer.cornerRadius = 20
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
