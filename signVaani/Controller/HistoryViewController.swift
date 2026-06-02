import UIKit
import PhotosUI
import AVFoundation

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
    
    private func setupSortButton() {
        updateSortMenu()
    }
    
    private func updateSortMenu() {
        // Create menu items
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
    
    //Add Video
    @IBAction func addVideoTapped(_ sender: UIButton) {
        if !searchBar.isHidden {
            hideSearchBar()
        }

        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen

        // Open picker
        self.present(picker, animated: true) {
            // Show alert after picker opens
            let alert = UIAlertController(
                title: "Note",
                message: "Please select a video shorter than 1 minute.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            picker.present(alert, animated: true)
        }
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPlayer" {
            if let destination = segue.destination as? LiveViewController,
               let video = selectedVideo {
                let url = URL(fileURLWithPath: video.videoPath)
                destination.incomingVideoURL = url
            }
        }
    }
    
    private func checkVideoDuration(from url: URL) {
        let asset = AVURLAsset(url: url)

        Task { [weak self] in
            guard let self = self else { return }

            // Check audio first
            let hasAudio = await checkVideoHasAudio(asset)

            if !hasAudio {
                await MainActor.run {
                    self.showNoAudioAlert()
                }
                return
            }

            do {
                let loadedDuration = try await asset.load(.duration)
                let seconds = loadedDuration.seconds

                await MainActor.run {
                    if seconds > 60 {
                        self.showLongVideoAlert()
                    } else {
                        self.proceedWithVideoUpload(from: url, duration: seconds)
                    }
                }

            } catch {
                await MainActor.run {
                    self.showErrorAlert(message: "Failed to read video duration.")
                }
            }
        }
    }
    
    private func checkVideoHasAudio(_ asset: AVAsset) async -> Bool {
        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            return !audioTracks.isEmpty
        } catch {
            return false
        }
    }
    
    private func showNoAudioAlert() {
        let alert = UIAlertController(
            title: "No Audio Found",
            message: "The selected video does not contain audio. Please choose another video.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
            self?.addVideoTapped(self?.addVideo ?? UIButton())
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))

        present(alert, animated: true)
    }
    
    private func showLongVideoAlert() {
        let alert = UIAlertController(
            title: "Video Too Long",
            message: "Please select a video shorter than 1 minute. Your video exceeds the time limit.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
            self?.addVideoTapped(self?.addVideo ?? UIButton())
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        present(alert, animated: true)
    }
    
    private func proceedWithVideoUpload(from sourceURL: URL, duration: Double) {
        let fileName = UUID().uuidString + ".mov"
        let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            // Check if file already exists and remove it
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the video file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            let alert = UIAlertController(
                title: "Video Confirmation",
                message: String(format: "Video duration: %.1f seconds\n\nAre you sure you want to upload this video?", duration),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Proceed", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                let newVideo = VideoItem(
                    id: UUID().uuidString,
                    title: "New Video",
                    thumbnail: "thumbnail",
                    videoPath: destinationURL.path,
                    duration: duration,
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
            
            alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
                // Delete the copied file if user chooses another video
                try? FileManager.default.removeItem(at: destinationURL)
                // Reopen picker
                guard let self = self else { return }
                self.addVideoTapped(self.addVideo)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { _ in
                // Clean up the copied file
                try? FileManager.default.removeItem(at: destinationURL)
            })
            
            self.present(alert, animated: true)
            
        } catch {
            showErrorAlert(message: "Failed to save video: \(error.localizedDescription)")
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

// MARK: - PHPickerViewControllerDelegate
extension HistoryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            // Use the modern API to load the video
            itemProvider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] (item, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.showErrorAlert(message: "Failed to load video: \(error.localizedDescription)")
                        return
                    }
                    
                    // Handle both URL and Data cases
                    if let url = item as? URL {
                        // Create a temporary copy since the original might be inaccessible
                        self.processVideoFromURL(url)
                    } else if let data = item as? Data {
                        // Save data to temporary file
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                        do {
                            try data.write(to: tempURL)
                            self.processVideoFromURL(tempURL)
                        } catch {
                            self.showErrorAlert(message: "Failed to process video data")
                        }
                    } else {
                        self.showErrorAlert(message: "Unsupported video format")
                    }
                }
            }
        }
    }
    
    private func processVideoFromURL(_ url: URL) {
        // Create a permanent copy in our app's directory
        let fileName = UUID().uuidString + ".mov"
        let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        do {
            // Remove if exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Now check duration on our local copy
            checkVideoDuration(from: destinationURL)
        } catch {
            showErrorAlert(message: "Failed to save video: \(error.localizedDescription)")
        }
    }
}
