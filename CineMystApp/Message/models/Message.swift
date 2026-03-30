//
//  Message.swift
//  CineMystApp
//
//  Created by AI Assistant
//

import Foundation

/// Represents a single message in a conversation
struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String
    let messageType: MessageType
    let isRead: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum MessageType: String, Codable {
        case text
        case image
        case video
        case audio
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
