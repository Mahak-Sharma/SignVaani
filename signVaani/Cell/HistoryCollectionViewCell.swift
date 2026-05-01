import UIKit

class HistoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var moreButton: UIButton!
    
    // callbacks closures - used to communicate with the view controller
    var renameAction: (() -> Void)?
    var deleteAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 12
        thumbnailImageView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailImageView.image = nil
        titleLabel.text = nil
        moreButton.menu = nil
    }
    
 // set up the rename and delete menu
    private func setupMoreButtonMenu() {

        let rename = UIAction(
            title: "Rename",
            image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
            self?.renameAction?()
        }

        let delete = UIAction(
            title: "Delete",
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.deleteAction?()
        }

        let menu = UIMenu(
            title: "",
            children: [rename, delete]
        )

        moreButton.showsMenuAsPrimaryAction = true
        moreButton.menu = menu
    }
    
    func configureCell(with video: VideoItem) {

        titleLabel.text = video.title

        thumbnailImageView.image = UIImage(named: video.thumbnail)

        setupMoreButtonMenu()
    }
}
