import UIKit

class signUpViewController: UIViewController, AvatarSelectionDelegate {

    // MARK: - OUTLETS

    @IBOutlet weak var profileImageChange: UIButton!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var bigView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!

    // MARK: - VIEW LIFE CYCLE

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        setupUI()
        loadSavedProfile()

        profileImageChange.addTarget(
            self,
            action: #selector(profileImageChangeButtonTapped),
            for: .touchUpInside
        )

        continueButton.addTarget(
            self,
            action: #selector(continueButtonPressed),
            for: .touchUpInside
        )

        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )

        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    

    // MARK: - UI

    private func setupUI() {

        title = "Create Your Profile"

        bigView.layer.cornerRadius = 20

        outerView.layer.cornerRadius = outerView.frame.height / 2
           innerView.layer.cornerRadius = innerView.frame.height / 2

        profileImageChange.layer.cornerRadius = 18
        profileImageChange.clipsToBounds = true

        continueButton.layer.cornerRadius = 12
        profileImageView.layer.cornerRadius =
            profileImageView.frame.width / 2

        profileImageView.clipsToBounds = true
        nameTextField.layer.cornerRadius = 12
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.systemGray4.cgColor
    }

    // MARK: - PROFILE IMAGE

    @objc private func profileImageChangeButtonTapped() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let imageVC = storyboard.instantiateViewController(
            withIdentifier: "ImageViewController"
        ) as? ImageViewController else {

            print("ImageViewController not found")
            return
        }

        imageVC.delegate = self

        present(imageVC, animated: true)
    }

    func didSelectAvatar(image: UIImage) {

        profileImageView.image = image

        if let imageData = image.pngData() {
            UserDefaults.standard.set(
                imageData,
                forKey: "userAvatar"
            )
        }
    }

    // MARK: - CONTINUE

    @objc private func continueButtonPressed() {

        let name = nameTextField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else {
            showAlert(message: "Please enter your name")
            return
        }

        UserDefaults.standard.set(name, forKey: "userName")

        // Important flag used by SceneDelegate
        UserDefaults.standard.set(true, forKey: "hasCompletedSignup")
        UserDefaults.standard.synchronize()

        print(
            "hasCompletedSignup = \(UserDefaults.standard.bool(forKey: "hasCompletedSignup"))"
        )

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let homeVC = storyboard.instantiateViewController(
            withIdentifier: "HomeViewController"
        )

        if let window = self.view.window ??
            UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {

            window.rootViewController =
                UINavigationController(rootViewController: homeVC)

            window.makeKeyAndVisible()
        }
    }

    // MARK: - LOAD DATA

    private func loadSavedProfile() {

        nameTextField.text =
            UserDefaults.standard.string(forKey: "userName")

        if let imageData = UserDefaults.standard.data(
            forKey: "userAvatar"
        ) {

            profileImageView.image =
                UIImage(data: imageData)
        }
    }

    // MARK: - KEYBOARD

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - ALERT

    private func showAlert(message: String) {

        let alert = UIAlertController(
            title: "Info",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: .default
            )
        )

        present(alert, animated: true)
    }
}
