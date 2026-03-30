//
//  ConversationModel.swift
//  CineMystApp
//
//  Created by AI Assistant
//

import Foundation

/// Represents a conversation between users
struct ConversationModel: Codable, Identifiable {
    let id: UUID
    let participant1Id: UUID
    let participant2Id: UUID
    let lastMessageId: UUID?
    let lastMessageContent: String?
    let lastMessageTime: Date?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case participant1Id = "participant1_id"
        case participant2Id = "participant2_id"
        case lastMessageId = "last_message_id"
        case lastMessageContent = "last_message_content"
        case lastMessageTime = "last_message_time"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// User profile information for displaying in conversations
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let fullName: String?
    let username: String?
    let avatarUrl: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case avatarUrl = "avatar_url"
        case bio
    }
}
