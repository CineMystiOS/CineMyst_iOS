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

    // MARK: - Helper
    private func currentUserId() async throws -> String {
        try await supabase.auth.session.user.id.uuidString
    }
}
