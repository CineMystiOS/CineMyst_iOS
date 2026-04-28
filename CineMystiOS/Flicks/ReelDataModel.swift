//
//  Reel Data Model.swift
//  CineMystApp
//
//  Created by user@55 on 25/11/25.
//

import Foundation
import UIKit

struct Reel {
    let id: String
    let userId: String
    let videoURL: String
    let authorName: String
    let authorUsername: String?
    let authorAvatar: UIImage?
    let authorAvatarURL: String?
    var likes: String
    var comments: String
    var shares: String
    var rawCommentsCount: Int
    var rawLikesCount: Int
    let audioTitle: String
    let caption: String?
    var isLiked: Bool
    let allowComments: Bool   // from flick.allow_comments
    let thumbnailUrl: String? // Added for instant preview
    var latestLikerUsername: String?
    
    // Helper to create from Flick model
    static func from(flick: Flick, isLiked: Bool = false) -> Reel {
        return Reel(
            id: flick.id,
            userId: flick.userId ?? "",
            videoURL: flick.videoUrl ?? "",
            authorName: flick.fullName ?? flick.username ?? "Unknown",
            authorUsername: flick.username,
            authorAvatar: nil,
            authorAvatarURL: flick.profilePictureUrl,
            likes: formatCount(flick.likesCount ?? 0),
            comments: formatCount(flick.commentsCount ?? 0),
            shares: formatCount(flick.sharesCount ?? 0),
            rawCommentsCount: flick.commentsCount ?? 0,
            rawLikesCount: flick.likesCount ?? 0,
            audioTitle: flick.audioTitle ?? "Original Audio",
            caption: flick.caption,
            isLiked: isLiked,
            allowComments: flick.allowComments ?? true,
            thumbnailUrl: flick.thumbnailUrl,
            latestLikerUsername: flick.latestLikerUsername
        )
    }
    
    static func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}
struct ReelComment {
    let username: String
    let text: String
    let timeAgo: String
}

struct ShareUser {
    let id: String
    let name: String
    let username: String
    let avatarUrl: String?
}
