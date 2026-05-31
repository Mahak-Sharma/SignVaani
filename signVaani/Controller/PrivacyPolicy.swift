//
//  PrivacyPolicy.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 11/04/26.
//

import UIKit

class PrivacyPolicy: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)}
}
