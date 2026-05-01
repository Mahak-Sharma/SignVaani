//
//  Model.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 1/30/26.
//

import Foundation

struct VideoItem: Codable {
    let id: String
    var title: String
    var thumbnail: String
    let videoPath: String   
    let duration: TimeInterval
    let createdAt: Date
}

//enum VideoSource: Codable {
//    case youtube(link: String)
//    case photos(localPath: String)
//}

//struct Playlist: Codable {
//    let id: String
//    var title: String
//    var videos: [VideoItem]
//}

// MARK: Helpers
//extension Playlist {
//    var videoCount: Int { videos.count }
//    var coverThumbnail: String { videos.first?.thumbnail ?? "placeholder" }
//}
struct GlossEvent {
    let gloss: String
    let time: Double
}
//extension Playlist {
//
//    var topVideos: [VideoItem] {
//        return Array(videos.prefix(4))
//    }
//
//}
