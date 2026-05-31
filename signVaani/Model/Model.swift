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
struct GlossEvent {
    let gloss: String
    let time: Double
}

