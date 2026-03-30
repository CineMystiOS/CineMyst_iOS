//
//  ConnectionManager.swift
//  CineMystApp
//
//  Manages all connection-related operations

import Foundation
import Supabase

class ConnectionManager {
    static let shared = ConnectionManager()
    private init() {}
    
    private var client: SupabaseClient { supabase }
    
    // MARK: - Send Connection Request
    func sendConnectionRequest(to receiverId: String) async throws {
        guard let currentUser = try await AuthManager.shared.currentSession() else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let requesterId = currentUser.user.id.uuidString
        
        // Insert new connection with pending status
        let connectionData: [String: String] = [
            "requester_id": requesterId,
            "receiver_id": receiverId,
            "status": "pending"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: connectionData)
        
        try await client
            .from("connections")
            .insert(connectionData, returning: .representation)
            .execute()
        
        print("✅ Connection request sent to \(receiverId)")
    }
    
    // MARK: - Get Connection State
    func getConnectionState(currentUserId: String, otherUserId: String) async throws -> ConnectionState {
        let response = try await client
            .from("connections")
            .select()
            .or("and(requester_id.eq.\(currentUserId),receiver_id.eq.\(otherUserId)),and(requester_id.eq.\(otherUserId),receiver_id.eq.\(currentUserId))")
            .execute()
        
        let decoder = JSONDecoder()
        let connections = try decoder.decode([Connection].self, from: response.data)
        
        guard let connection = connections.first else {
            return .notConnected
        }
        
        if connection.status == .rejected {
            return .rejected
        }
        
        if connection.status == .accepted {
            return .connected
        }
        
        // Pending - determine if sent or received
        if connection.requesterId == currentUserId {
            return .requestSent
        } else {
            return .requestReceived
        }
    }
    
    // MARK: - Accept Connection Request
    func acceptConnectionRequest(from requesterId: String) async throws {
        guard let currentUser = try await AuthManager.shared.currentSession() else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let receiverId = currentUser.user.id.uuidString
        
        try await client
            .from("connections")
            .update(["status": "accepted"])
            .eq("requester_id", value: requesterId)
            .eq("receiver_id", value: receiverId)
            .execute()
        
        print("✅ Connection request accepted")
    }
    
    // MARK: - Reject Connection Request
    func rejectConnectionRequest(from requesterId: String) async throws {
        guard let currentUser = try await AuthManager.shared.currentSession() else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let receiverId = currentUser.user.id.uuidString
        
        try await client
            .from("connections")
            .update(["status": "rejected"])
            .eq("requester_id", value: requesterId)
            .eq("receiver_id", value: receiverId)
            .execute()
        
        print("✅ Connection request rejected")
    }
    
    // MARK: - Cancel Connection Request
    func cancelConnectionRequest(to receiverId: String) async throws {
        guard let currentUser = try await AuthManager.shared.currentSession() else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let requesterId = currentUser.user.id.uuidString
        
        try await client
            .from("connections")
            .delete()
            .eq("requester_id", value: requesterId)
            .eq("receiver_id", value: receiverId)
            .execute()
        
        print("✅ Connection request cancelled")
    }
    
    // MARK: - Remove Connection
    func removeConnection(with userId: String) async throws {
        guard let currentUser = try await AuthManager.shared.currentSession() else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        let currentUserId = currentUser.user.id.uuidString
        
        // Delete connection in either direction
        try await client
            .from("connections")
            .delete()
            .or("and(requester_id.eq.\(currentUserId),receiver_id.eq.\(userId)),and(requester_id.eq.\(userId),receiver_id.eq.\(currentUserId))")
            .execute()
        
        print("✅ Connection removed")
    }
    
    // MARK: - Fetch User's Connections
    func fetchUserConnections(userId: String, limit: Int = 50) async throws -> [ConnectedUser] {
        // Get all connections where status is 'accepted' for this user
        let response = try await client
            .from("connections")
            .select("""
                requester_id,
                receiver_id
            """)
            .or("and(requester_id.eq.\(userId),status.eq.accepted),and(receiver_id.eq.\(userId),status.eq.accepted)")
            .limit(limit)
            .execute()
        
        let decoder = JSONDecoder()
        let connections = try decoder.decode([Connection].self, from: response.data)
        
        // Get the connected user IDs
        var connectedUserIds: [String] = []
        for connection in connections {
            if connection.requesterId == userId {
                connectedUserIds.append(connection.receiverId)
            } else {
                connectedUserIds.append(connection.requesterId)
            }
        }
        
        guard !connectedUserIds.isEmpty else {
            return []
        }
        
        // Fetch profile data for all connected users
        var allUsers: [ConnectedUser] = []
        for userId in connectedUserIds {
            let profileResponse = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
            
            let profile = try decoder.decode(ProfileRecord.self, from: profileResponse.data)
            
            let connectedUser = ConnectedUser(
                id: profile.id,
                username: profile.username ?? "Unknown",
                fullName: profile.fullName,
                profilePictureUrl: profile.profilePictureUrl,
                role: profile.role
            )
            
            allUsers.append(connectedUser)
        }
        
        return allUsers
    }
    
    // MARK: - Get Connection Count
    func getConnectionCount(userId: String) async throws -> Int {
        let response = try await client
            .from("connections")
            .select("id")
            .or("and(requester_id.eq.\(userId),status.eq.accepted),and(receiver_id.eq.\(userId),status.eq.accepted)")
            .execute()
        
        let decoder = JSONDecoder()
        let connections = try decoder.decode([Connection].self, from: response.data)
        return connections.count
    }
}
