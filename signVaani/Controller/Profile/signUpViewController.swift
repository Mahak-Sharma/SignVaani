//
//  signUpViewController.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 27/03/26.
//

import UIKit

class signUpViewController: UIViewController {

    // MARK: - OUTLETS
    @IBOutlet weak var bigView: UIView!
    @IBOutlet weak var userNameView: UIView!
    @IBOutlet weak var genderView: UIView!
    @IBOutlet weak var dobView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var genderSegment: UISegmentedControl!
    @IBOutlet weak var dobPicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIButton!

    // MARK: - VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSavedProfile()
        let tap = UITapGestureRecognizer(
                    target: self,
                    action: #selector(dismissKeyboard)
                )

                view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    @objc func dismissKeyboard() {
            view.endEditing(true)
        }
    // MARK: - VIEW DID LAYOUT
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupGradient()
    }

    // MARK: - UI SETUP
    func setupUI() {
        bigView.layer.cornerRadius = 20
        userNameView.layer.cornerRadius = 12
        genderView.layer.cornerRadius = 12
        dobView.layer.cornerRadius = 12
        saveButton.layer.cornerRadius = 12
        
        dobPicker.datePickerMode = .date
        dobPicker.maximumDate = Date()
        genderSegment.selectedSegmentIndex = 0
    }

    // MARK: - GRADIENT
    func setupGradient() {
        view.layer.sublayers?.removeAll { $0.name == "gradientLayer" }
        
        let gradient = CAGradientLayer()
        gradient.name = "gradientLayer"
        gradient.colors = [
            UIColor(red: 234/255, green: 242/255, blue: 255/255, alpha: 1).cgColor,
            UIColor(red: 163/255, green: 198/255, blue: 255/255, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.7]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - CONTINUE BUTTON
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let name = nameTextField.text ?? ""
        
        // Validate inputs
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showAlert(message: "Please enter your name")
            return
        }
        
        let gender = genderSegment.titleForSegment(at: genderSegment.selectedSegmentIndex) ?? ""
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dobString = formatter.string(from: dobPicker.date)
        
        // SAVE USER DATA
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(gender, forKey: "userGender")
        UserDefaults.standard.set(dobString, forKey: "userDOB")
        
        // MARK SIGNUP AS COMPLETED
        UserDefaults.standard.set(true, forKey: "hasCompletedSignup")
        UserDefaults.standard.synchronize()
        
        print("SIGNUP COMPLETED: \(UserDefaults.standard.bool(forKey: "hasCompletedSignup"))")
        
        // Replace the entire navigation stack and go to Home
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        
        // This completely replaces the root view controller using a scene-aware approach
        if let window = self.view.window ?? (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })) {
            window.rootViewController = UINavigationController(rootViewController: homeVC)
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - LOAD SAVED PROFILE
    func loadSavedProfile() {
        nameTextField.text = UserDefaults.standard.string(forKey: "userName")
        
        let savedGender = UserDefaults.standard.string(forKey: "userGender")
        if savedGender == "Male" {
            genderSegment.selectedSegmentIndex = 0
        } else if savedGender == "Female" {
            genderSegment.selectedSegmentIndex = 1
        } else if savedGender == "Other" {
            genderSegment.selectedSegmentIndex = 2
        }
        
        if let dob = UserDefaults.standard.string(forKey: "userDOB") {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            if let date = formatter.date(from: dob) {
                dobPicker.date = date
            }
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

