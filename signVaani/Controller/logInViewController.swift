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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
