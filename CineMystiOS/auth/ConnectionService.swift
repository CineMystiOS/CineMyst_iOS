//
//  ConnectionService.swift
//  CineMystApp
//
//  Handles follow / connection requests via the public.connections table
//  Schema: id, requester_id, receiver_id, status ("pending" | "accepted"), created_at

import Foundation
import Supabase

final class ConnectionService {
    static let shared = ConnectionService()
    private init() {}

    // MARK: - Send follow request
    func sendRequest(to receiverId: String) async throws {
        let uid = try await currentUserId()
        guard uid != receiverId else {
            throw NSError(
                domain: "ConnectionService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "You cannot connect with yourself."]
            )
        }

        struct NewConn: Encodable {
            let requester_id: String
            let receiver_id:  String
            let status:       String
        }

        // Upsert so repeated taps don't duplicate rows
        try await supabase
            .from("connections")
            .upsert(
                NewConn(requester_id: uid, receiver_id: receiverId, status: "pending"),
                onConflict: "requester_id,receiver_id"
            )
            .execute()
    }

    // MARK: - Cancel / unfollow
    func cancelRequest(to receiverId: String) async throws {
        let uid = try await currentUserId()
        try await supabase
            .from("connections")
            .delete()
            .eq("requester_id", value: uid)
            .eq("receiver_id",  value: receiverId)
            .execute()
    }

    // MARK: - Check if following
    func isFollowing(userId: String) async throws -> Bool {
        let uid = try await currentUserId()
        let res = try await supabase
            .from("connections")
            .select("id")
            .eq("requester_id", value: uid)
            .eq("receiver_id",  value: userId)
            .execute()
        return !res.data.isEmpty
    }

    // MARK: - Accept a request
    func accept(requesterId: String) async throws {
        let uid = try await currentUserId()
        try await supabase
            .from("connections")
            .update(["status": "accepted"])
            .eq("requester_id", value: requesterId)
            .eq("receiver_id",  value: uid)
            .execute()
    }

    // MARK: - Fetch following users
    func fetchFollowing() async throws -> [ProfileRecord] {
        let uid = try await currentUserId()
        let response = try await supabase
            .from("connections")
            .select("receiver_id")
            .eq("requester_id", value: uid)
            .eq("status", value: "accepted")
            .execute()
        
        // This is a bit inefficient (N+1), but for a small following list it's okay.
        // Better would be a join if the schema allowed easily.
        let rows = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] ?? []
        let ids = rows.compactMap { $0["receiver_id"] as? String }
        
        guard !ids.isEmpty else { return [] }
        
        let profileRes = try await supabase
            .from("profiles")
            .select("*")
            .in("id", value: ids)
            .execute()
            
        return try JSONDecoder().decode([ProfileRecord].self, from: profileRes.data)
    }

    // MARK: - Search users
    func searchUsers(query: String) async throws -> [ProfileRecord] {
        let response = try await supabase
            .from("profiles")
            .select("*")
            .ilike("username", value: "\(query)%")
            .limit(10)
            .execute()
            
        return try JSONDecoder().decode([ProfileRecord].self, from: response.data)
    }

    // MARK: - Helper
    private func currentUserId() async throws -> String {
        try await supabase.auth.session.user.id.uuidString
    }
}
