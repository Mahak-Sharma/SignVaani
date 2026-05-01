import UIKit
import PhotosUI

class HistoryViewController: UIViewController {
  
    @IBOutlet weak var emptyImage: UIView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addVideo: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    
    // Search bar
    private var searchBar: UISearchBar!
    private var isSearching = false
    private var filteredVideos: [VideoItem] = []
    
    // Sort options
    enum SortOrder {
        case newest
        case oldest
        case aToZ
        case zToA
    }
    //setting current sorting display of video
    private var currentSort: SortOrder = .newest
    
    private var videos: [VideoItem] {
        return HistoryManager.shared.videos
    }
    
    private var displayVideos: [VideoItem] {
        var videosToShow = isSearching ? filteredVideos : videos
        
        // Apply sorting
        switch currentSort {
        case .newest:
            videosToShow.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            videosToShow.sort { $0.createdAt < $1.createdAt }
        case .aToZ:
            videosToShow.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .zToA:
            videosToShow.sort { $0.title.lowercased() > $1.title.lowercased() }
        }
        
        return videosToShow
    }

    var selectedVideo: VideoItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchBar()
        setupSortButton()
        updateEmptyState()
        emptyImage.layer.cornerRadius = 52
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
    
    private func setupSortButton() {
        // Configure sort button with SF Symbol (arrow up down)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        _ = UIImage(systemName: "arrow.up.arrow.down", withConfiguration: symbolConfig)
        
//        sortButton.setTitle("Sort", for: .normal)
//        sortButton.setImage(sortImage, for: .normal)
//        sortButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        sortButton.tintColor = .systemBlue
        
        // Adjust spacing between image and title
//        sortButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
//        sortButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        
        // Create compact menu
        updateSortMenu()
    }
    
    private func updateSortMenu() {
        // Create menu items with ARROW icons (no calendar)
        let newest = UIAction(title: "Newest First") { [weak self] _ in
            self?.currentSort = .newest
            self?.refreshDisplay()
        }
        
        let oldest = UIAction(title: "Oldest First") { [weak self] _ in
            self?.currentSort = .oldest
            self?.refreshDisplay()
        }
        
        let aToZ = UIAction(title: "A to Z") { [weak self] _ in
            self?.currentSort = .aToZ
            self?.refreshDisplay()
        }
        
        let zToA = UIAction(title: "Z to A") { [weak self] _ in
            self?.currentSort = .zToA
            self?.refreshDisplay()
        }
        
        // Add checkmark to current selected option
        switch currentSort {
        case .newest:
            newest.state = .on
        case .oldest:
            oldest.state = .on
        case .aToZ:
            aToZ.state = .on
        case .zToA:
            zToA.state = .on
        }
        
        // Create menu
        let menu = UIMenu(title: "Sort By",
                         image: UIImage(systemName: "arrow.up.arrow.down"),
                         children: [newest, oldest, aToZ, zToA])
        
        sortButton.menu = menu
        sortButton.showsMenuAsPrimaryAction = true
    }
    
    private func refreshDisplay() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateEmptyState()
            self.updateSortMenu()
        }
    }
    
    private func setupSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search Videos"
        searchBar.showsCancelButton = true
        searchBar.backgroundImage = UIImage()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isHidden = true
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            searchBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        searchBar.isHidden = false
        searchBar.alpha = 0
        searchButton.isHidden = true
        searchBar.becomeFirstResponder()
        
        UIView.animate(withDuration: 0.3) {
            self.searchBar.alpha = 1
        }
    }
    
    private func hideSearchBar() {
        searchBar.resignFirstResponder()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBar.alpha = 0
        }) { _ in
            self.searchBar.isHidden = true
            self.searchButton.isHidden = false
            self.searchBar.text = ""
            self.isSearching = false
            self.filteredVideos.removeAll()
            self.collectionView.reloadData()
            self.updateEmptyState()
        }
    }
    
    // MARK: - Add Video
    @IBAction func addVideoTapped(_ sender: UIButton) {
        if !searchBar.isHidden {
            hideSearchBar()
        }
        
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self

        present(picker, animated: true)
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            UINib(nibName: "HistoryCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "HistoryCollectionViewCell"
        )

        collectionView.collectionViewLayout = generateLayout()
    }

    func updateEmptyState() {
        let isEmpty = displayVideos.isEmpty
        
        emptyView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    private func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(110)
        )

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)

        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 16, bottom: 12, trailing: 16
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        let titleColor = UIColor(red: 47/255, green: 74/255, blue: 107/255, alpha: 1)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPlayer" {
            if let destination = segue.destination as? LocalVideoAvatarViewController,
               let video = selectedVideo {
                let url = URL(fileURLWithPath: video.videoPath)
                destination.selectedVideoURL = url
            }
        }
    }
}

// MARK: - Collection DataSource
extension HistoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return displayVideos.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "HistoryCollectionViewCell",
            for: indexPath
        ) as? HistoryCollectionViewCell else {
            fatalError("Cell not found")
        }
        
        let video = displayVideos[indexPath.item]
        cell.configureCell(with: video)

        // DELETE
        cell.deleteAction = { [weak self] in
            guard let self = self else { return }

            let alert = UIAlertController(
                title: "Delete Video",
                message: "Are you sure?",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Find and delete from original array
                if let originalIndex = self.videos.firstIndex(where: { $0.id == video.id }) {
                    HistoryManager.shared.videos.remove(at: originalIndex)
                }
                
                // Update filtered list if searching
                if self.isSearching {
                    self.filterContentForSearchText(self.searchBar.text ?? "")
                }
                
                self.collectionView.reloadData()
                self.updateEmptyState()
            })

            self.present(alert, animated: true)
        }

        // RENAME
        cell.renameAction = { [weak self] in
            guard let self = self else { return }

            let alert = UIAlertController(
                title: "Rename Video",
                message: "Enter new name",
                preferredStyle: .alert
            )

            alert.addTextField { textField in
                textField.text = video.title
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                guard let newName = alert.textFields?.first?.text,
                      !newName.isEmpty else { return }
                
                // Update the actual video in HistoryManager
                if let originalIndex = self.videos.firstIndex(where: { $0.id == video.id }) {
                    HistoryManager.shared.videos[originalIndex].title = newName
                }
                
                // Update filtered list if searching
                if self.isSearching {
                    self.filterContentForSearchText(self.searchBar.text ?? "")
                } else {
                    self.collectionView.reloadData()
                }
            })

            self.present(alert, animated: true)
        }

        return cell
    }
}

// MARK: - Collection Delegate
extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        selectedVideo = displayVideos[indexPath.item]
        performSegue(withIdentifier: "goToPlayer", sender: self)
    }
}

// MARK: - UISearchBarDelegate
extension HistoryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterContentForSearchText(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredVideos.removeAll()
        } else {
            isSearching = true
            filteredVideos = videos.filter { video in
                return video.title.lowercased().contains(searchText.lowercased())
            }
        }
        
        collectionView.reloadData()
        updateEmptyState()
    }
}

// MARK: - PHPicker
extension HistoryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
            itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                
                guard let url = url else { return }

                let fileName = UUID().uuidString + ".mov"
                let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent(fileName)

                try? FileManager.default.copyItem(at: url, to: destinationURL)

                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Video Confirmation",
                        message: "Are you sure you want to upload this video?",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Proceed", style: .default) { _ in
                        let newVideo = VideoItem(
                            id: UUID().uuidString,
                            title: "New Video",
                            thumbnail: "thumbnail",
                            videoPath: destinationURL.path,
                            duration: 0,
                            createdAt: Date()
                        )

                        HistoryManager.shared.addVideo(newVideo)
                        
                        if self.isSearching {
                            self.hideSearchBar()
                        }
                        
                        self.collectionView.reloadData()
                        self.updateEmptyState()
                        self.selectedVideo = newVideo
                        self.performSegue(withIdentifier: "goToPlayer", sender: self)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { _ in
                        self.addVideoTapped(self.addVideo)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))

                    self.present(alert, animated: true)
                }
            }
        }
    }
}
