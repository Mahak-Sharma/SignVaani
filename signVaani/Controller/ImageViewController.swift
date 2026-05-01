import UIKit

protocol AvatarSelectionDelegate: AnyObject {
    func didSelectAvatar(image: UIImage)
}

class ImageViewController: UIViewController {
    
    @IBOutlet weak var tickButton: UIButton!
    weak var delegate: AvatarSelectionDelegate?

    var selectedImage : UIImage?
    var selectedImageView : UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enableTap(forTag: 1)
        enableTap(forTag: 2)
        enableTap(forTag: 3)
        enableTap(forTag: 4)
        enableTap(forTag: 5)
        enableTap(forTag: 6)
         
        // force button image to use tintColor
        if let img = tickButton.image(for: .normal) {
            tickButton.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        //when pfp is not selected in the pop up : default state
        tickButton.tintColor = .lightGray
        tickButton.isEnabled = false
    }

    func enableTap(forTag tag: Int) {

        if let imageView = view.viewWithTag(tag) as? UIImageView {

            imageView.isUserInteractionEnabled = true

            let tap = UITapGestureRecognizer(
                target: self,
                action: #selector(avatarTapped(_:))
            )

            imageView.addGestureRecognizer(tap)
        }
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
    @objc func avatarTapped(_ sender: UITapGestureRecognizer) {

        guard let imageView = sender.view as? UIImageView,
              let image = imageView.image else { return }

        // remove border from previously selected pfp
        selectedImageView?.layer.borderWidth = 0

        // highlight selected pfp with blue ring
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true

        // store selection
        selectedImageView = imageView
        selectedImage = image
        
        //when image is selected, then the tick button color will be set to blue
        tickButton.tintColor = .systemBlue
        tickButton.isEnabled = true

    }
    @IBAction func tickPressed(_ sender: UIButton) {

        guard let image = selectedImage else { return }

        delegate?.didSelectAvatar(image: image)
        dismiss(animated: true)
    }
}
