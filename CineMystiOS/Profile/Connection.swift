//
//  Connection.swift
//  CineMystApp
//
//  Connection model for LinkedIn-style professional networking
//

import Foundation

struct Connection: Codable {
    let id: String
    let requesterId: String
    let receiverId: String
    let status: ConnectionStatus
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case receiverId = "receiver_id"
        case status
        case createdAt = "created_at"
    }
}

enum ConnectionStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
}

// MARK: - For displaying connection state in UI
enum ConnectionState {
    case notConnected // No record exists
    case requestSent // Current user sent request (pending)
    case requestReceived // Current user received request (pending)
    case connected // Accepted connection
    case rejected // Rejected connection
}

// MARK: - Connected User (for connections list)
struct ConnectedUser: Codable {
    let id: String
    let username: String
    let fullName: String?
    let profilePictureUrl: String?
    let role: String?
}
