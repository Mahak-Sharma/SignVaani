import Foundation

final class HistoryManager {

    static let shared = HistoryManager()
    private let saveKey = "saved_videos"
    
    private init() {
        loadVideos()  // load on app start
    }

    // MARK: - Source of truth
    var videos: [VideoItem] = [] {
        didSet {
            saveVideos()  // auto-save on any change
        }
    }

    // MARK: - Add Video (FIXED)
    func addVideo(_ video: VideoItem) {
        
        // ✅ Remove duplicate based on videoPath (NOT id)
        videos.removeAll { $0.videoPath == video.videoPath }
        
        // Insert latest at top
        videos.insert(video, at: 0)
        
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }

    // MARK: - Update Thumbnail (IMPORTANT)
    func updateThumbnail(for videoPath: String, thumbnail: String) {
        if let index = videos.firstIndex(where: { $0.videoPath == videoPath }) {
            videos[index].thumbnail = thumbnail
        }
    }

    // MARK: - Delete Video
    func deleteVideo(id: String) {
        videos.removeAll { $0.id == id }
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }

    // MARK: - Rename Video
    func renameVideo(id: String, newName: String) {
        if let index = videos.firstIndex(where: { $0.id == id }) {
            videos[index].title = newName
            NotificationCenter.default.post(name: .historyUpdated, object: nil)
        }
    }

    // MARK: - Save
    private func saveVideos() {
        do {
            let encoded = try JSONEncoder().encode(videos)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("❌ Save failed:", error)
        }
    }

    // MARK: - Load (with duplicate cleanup)
    private func loadVideos() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([VideoItem].self, from: data) else {
            return
        }

        // ✅ Remove duplicates using videoPath
        let unique = Dictionary(grouping: decoded, by: { $0.videoPath })
            .compactMap { $0.value.first }

        videos = unique
    }
}

// MARK: - Notification
extension Notification.Name {
    static let historyUpdated = Notification.Name("historyUpdated")
}

// MARK: - Helpers
extension HistoryManager {
    
    // Top 4 videos (for home screen)
    var topVideos: [VideoItem] {
        return Array(videos.prefix(4))
    }
}
