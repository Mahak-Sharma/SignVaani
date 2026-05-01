//
//  boardingViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 26/03/26.
//

import UIKit

class boardingViewController: UIViewController {

    @IBOutlet var getStarted: UIView!
    @IBOutlet weak var circle3: UIView!
    @IBOutlet weak var circle4: UIView!
    @IBOutlet weak var circle2: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bigCircleView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bigCircleView.layer.cornerRadius = 175
       topView.layer.cornerRadius = 89
        circle2.layer.cornerRadius = 120
        circle3.layer.cornerRadius = 175
        circle4.layer.cornerRadius = 89
      
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        circle3.bringSubviewToFront(getStarted)
        circle4.bringSubviewToFront(getStarted)
    }
}
