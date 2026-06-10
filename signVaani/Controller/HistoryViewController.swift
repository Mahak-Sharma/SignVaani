import UIKit
import PhotosUI
import AVFoundation
internal import Speech

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
    private var activeProcessingAlert: UIAlertController?

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
            
            do {
                let loadedDuration = try await asset.load(.duration)
                let seconds = loadedDuration.seconds
                
                guard seconds > 0 && !seconds.isNaN && !seconds.isInfinite else {
                    try? FileManager.default.removeItem(at: url)
                    await MainActor.run {
                        self.activeProcessingAlert?.dismiss(animated: false) {
                            self.showErrorAlert(message: "Could not determine video duration.")
                        }
                    }
                    return
                }
                
                print("Video duration:", seconds)

                if seconds > 60 {
                    print("LONG VIDEO DETECTED")
                    try? FileManager.default.removeItem(at: url)
                    await MainActor.run {
                        self.activeProcessingAlert?.dismiss(animated: false) {
                            self.showLongVideoAlert()
                        }
                    }
                    return
                }
                
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                var hasActualAudio = false
                if !audioTracks.isEmpty {
                    hasActualAudio = await self.checkVideoHasActualAudio(url)
                }
                
                await MainActor.run {
                    guard hasActualAudio else {
                        try? FileManager.default.removeItem(at: url)
                        self.activeProcessingAlert?.dismiss(animated: false) {
                            self.showNoSpeechAlert()
                        }
                        return
                    }

                    print("NORMAL VIDEO")
                    self.checkForSpeech(in: url, duration: seconds)
                }
                
            } catch {
                await MainActor.run {
                    try? FileManager.default.removeItem(at: url)
                    self.activeProcessingAlert?.dismiss(animated: false) {
                        self.showErrorAlert(message: "Failed to read video: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    //Speech Detection
    private func checkForSpeech(in url: URL, duration: Double) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.activeProcessingAlert?.dismiss(animated: false) {
                        self.proceedWithVideoUpload(from: url, duration: duration)
                    }
                }
                return
            }
            
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN")),
                  recognizer.isAvailable else {
                DispatchQueue.main.async {
                    self.activeProcessingAlert?.dismiss(animated: false) {
                        self.proceedWithVideoUpload(from: url, duration: duration)
                    }
                }
                return
            }
            
            guard let exportSession = AVAssetExportSession(
                asset: AVURLAsset(url: url),
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                DispatchQueue.main.async {
                    self.activeProcessingAlert?.dismiss(animated: false) {
                        self.proceedWithVideoUpload(from: url, duration: duration)
                    }
                }
                return
            }
            
            let tempAudioURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "_check_speech.m4a")
            try? FileManager.default.removeItem(at: tempAudioURL)
            
            let targetDuration = min(duration, 15.0)
            exportSession.timeRange = CMTimeRange(
                start: .zero,
                duration: CMTime(seconds: targetDuration, preferredTimescale: 600)
            )
            
            class SpeechCheckTracker {
                var isCompleted = false
            }
            let tracker = SpeechCheckTracker()
            
            var recognitionTask: SFSpeechRecognitionTask? = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if !tracker.isCompleted {
                    tracker.isCompleted = true
                    recognitionTask?.cancel()
                    try? FileManager.default.removeItem(at: tempAudioURL)
                    self.activeProcessingAlert?.dismiss(animated: false) {
                        self.proceedWithVideoUpload(from: url, duration: duration)
                    }
                }
            }
            
            Task {
                do {
                    try await exportSession.export(to: tempAudioURL, as: .m4a)
                    
                    let request = SFSpeechURLRecognitionRequest(url: tempAudioURL)
                    request.shouldReportPartialResults = false
                    request.requiresOnDeviceRecognition = false
                    
                    let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                        guard let self = self else {
                            try? FileManager.default.removeItem(at: tempAudioURL)
                            return
                        }
                        
                        if let error = error {
                            if !tracker.isCompleted {
                                tracker.isCompleted = true
                                try? FileManager.default.removeItem(at: tempAudioURL)
                                DispatchQueue.main.async {
                                    self.activeProcessingAlert?.dismiss(animated: false) {
                                        let nsError = error as NSError
                                        if nsError.code == 1110 {
                                            try? FileManager.default.removeItem(at: url)
                                            self.showNoSpeechAlert()
                                        } else {
                                            self.proceedWithVideoUpload(from: url, duration: duration)
                                        }
                                    }
                                }
                            }
                            return
                        }
                        
                        if let result = result, result.isFinal {
                            if !tracker.isCompleted {
                                tracker.isCompleted = true
                                try? FileManager.default.removeItem(at: tempAudioURL)
                                DispatchQueue.main.async {
                                    self.activeProcessingAlert?.dismiss(animated: false) {
                                        let transcript = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespaces)
                                        if transcript.isEmpty {
                                            try? FileManager.default.removeItem(at: url)
                                            self.showNoSpeechAlert()
                                        } else {
                                            self.proceedWithVideoUpload(from: url, duration: duration)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        if !tracker.isCompleted {
                            recognitionTask = task
                        } else {
                            task.cancel()
                        }
                    }
                    
                } catch {
                    try? FileManager.default.removeItem(at: tempAudioURL)
                    await MainActor.run {
                        if !tracker.isCompleted {
                            tracker.isCompleted = true
                            self.activeProcessingAlert?.dismiss(animated: false) {
                                self.proceedWithVideoUpload(from: url, duration: duration)
                            }
                        }
                    }
                }
            }
        }
    }
    private func checkVideoHasActualAudio(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        
        //Check audio track exists
        guard let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first else {
            return false
        }
        
        guard let reader = try? AVAssetReader(asset: asset) else {
            return true // Assume audio if we can't read
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        
        guard reader.canAdd(output) else { return true }
        reader.add(output)
        reader.timeRange = CMTimeRange(
            start: .zero,
            duration: CMTime(seconds: 5, preferredTimescale: 44100)
        )
        
        guard reader.startReading() else { return true }
        
        nonisolated(unsafe) let capturedOutput = output
        nonisolated(unsafe) let capturedReader = reader
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                
                let threshold: Float = 0.0005 // Lowered threshold
                var foundSound = false
                var totalSamplesChecked = 0
                let maxSamples = 44100 * 10 // 10 seconds worth
                
                while !foundSound,
                      totalSamplesChecked < maxSamples,
                      let sampleBuffer = capturedOutput.copyNextSampleBuffer() {
                    
                    guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                        continue
                    }
                    
                    let totalLength = CMBlockBufferGetDataLength(blockBuffer)
                    guard totalLength > 0 else { continue }
                    
                    var contiguousBuffer: CMBlockBuffer?
                    guard CMBlockBufferCreateContiguous(
                        allocator: nil,
                        sourceBuffer: blockBuffer,
                        blockAllocator: nil,
                        customBlockSource: nil,
                        offsetToData: 0,
                        dataLength: totalLength,
                        flags: 0,
                        blockBufferOut: &contiguousBuffer
                    ) == noErr, let contiguous = contiguousBuffer else { continue }
                    
                    var dataPointer: UnsafeMutablePointer<Int8>?
                    var dataLength = 0
                    
                    guard CMBlockBufferGetDataPointer(
                        contiguous,
                        atOffset: 0,
                        lengthAtOffsetOut: nil,
                        totalLengthOut: &dataLength,
                        dataPointerOut: &dataPointer
                    ) == noErr, let pointer = dataPointer else { continue }
                    
                    let sampleCount = dataLength / 4 // Float32 = 4 bytes
                    guard sampleCount > 0 else { continue }
                    
                    let floatPointer = UnsafeRawPointer(pointer)
                        .bindMemory(to: Float32.self, capacity: sampleCount)
                    let floatBuffer = UnsafeBufferPointer(start: floatPointer, count: sampleCount)
                    
                    // Calculate RMS
                    var sumOfSquares: Float = 0
                    for sample in floatBuffer {
                        sumOfSquares += sample * sample
                    }
                    let rms = sqrt(sumOfSquares / Float(sampleCount))
                    
                    if rms > threshold {
                        foundSound = true
                    }
                    
                    totalSamplesChecked += sampleCount
                }
                
                capturedReader.cancelReading()
                continuation.resume(returning: foundSound)
            }
        }
    }
    
    //Alerts
    private func showNoSpeechAlert() {
        let alert = UIAlertController(
            title: "No Speech Detected",
            message: "The selected video does not contain any speech. Please choose a video with someone speaking.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
            self?.addVideoTapped(self?.addVideo ?? UIButton())
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showLongVideoAlert() {
        let alert = UIAlertController(
            title: "Video Too Long",
            message: "Please select a video shorter than 1 minute.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
            self?.addVideoTapped(self?.addVideo ?? UIButton())
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    //proceedWithVideoUpload
    private func proceedWithVideoUpload(from localURL: URL, duration: Double) {
        let alert = UIAlertController(
            title: "Video Confirmation",
            message: String(format: "Duration: %.1f seconds\n\nProceed with this video?", duration),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Proceed", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let newVideo = VideoItem(
                id: UUID().uuidString,
                title: "New Video",
                thumbnail: "thumbnail",
                videoPath: localURL.path,
                duration: duration,
                createdAt: Date()
            )
            
            HistoryManager.shared.addVideo(newVideo)
            
            if self.isSearching { self.hideSearchBar() }
            
            self.collectionView.reloadData()
            self.updateEmptyState()
            self.selectedVideo = newVideo
            self.performSegue(withIdentifier: "goToPlayer", sender: self)
        })
        
        alert.addAction(UIAlertAction(title: "Choose Another Video", style: .default) { [weak self] _ in
            try? FileManager.default.removeItem(at: localURL)
            self?.addVideoTapped(self?.addVideo ?? UIButton())
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive) { _ in
            try? FileManager.default.removeItem(at: localURL)
        })
        
        present(alert, animated: true)
    }
    

}

//Collection DataSource
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

//Collection Delegate
extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        selectedVideo = displayVideos[indexPath.item]
        performSegue(withIdentifier: "goToPlayer", sender: self)
    }
}

//UISearchBarDelegate
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

//PHPickerViewControllerDelegate
extension HistoryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            let processingAlert = UIAlertController(
                title: nil,
                message: "Processing video...",
                preferredStyle: .alert
            )
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.startAnimating()
            indicator.translatesAutoresizingMaskIntoConstraints = false
            processingAlert.view.addSubview(indicator)
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: processingAlert.view.centerXAnchor),
                indicator.bottomAnchor.constraint(equalTo: processingAlert.view.bottomAnchor, constant: -16)
            ])
            self.activeProcessingAlert = processingAlert
            self.present(processingAlert, animated: true)
            
            guard let itemProvider = results.first?.itemProvider else { return }
            
            let typeIdentifiers = [
                UTType.movie.identifier,
                UTType.video.identifier,
                UTType.mpeg4Movie.identifier,
                "com.apple.quicktime-movie"
            ]
            
            let matchedType = typeIdentifiers.first {
                itemProvider.hasItemConformingToTypeIdentifier($0)
            }
            
            guard let typeIdentifier = matchedType else {
                self.showErrorAlert(message: "Unsupported video format.")
                return
            }
            
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] tempURL, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: "Failed to load video: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: "Could not access video file.")
                    }
                    return
                }
            
                let fileName = UUID().uuidString + "." + tempURL.pathExtension
                let destinationURL = FileManager.default.urls(
                    for: .documentDirectory, in: .userDomainMask
                )[0].appendingPathComponent(fileName)
                
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                } catch {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: "Failed to save video: \(error.localizedDescription)")
                    }
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.checkVideoDuration(from: destinationURL)
                }
            }
        }
    }
}
