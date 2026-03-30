//
//  MessagesService.swift
//  CineMystApp
//
//  Created by AI Assistant
//

import Foundation
import Supabase

class MessagesService {
    static let shared = MessagesService()
    
    // Use the global supabase instance defined in auth/Supabase.swift
    private var client: SupabaseClient { supabase }
    
    private init() {}
    
    // MARK: - Conversations
    
    /// Fetch all conversations for the current user
    func fetchConversations() async throws -> [(conversation: ConversationModel, otherUser: UserProfile)] {
        guard let currentUserId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔍 Fetching conversations for user: \(currentUserId.uuidString)")
        
        // Fetch conversations where current user is a participant
        let conversations: [ConversationModel] = try await client
            .from("conversations")
            .select()
            .or("participant1_id.eq.\(currentUserId.uuidString),participant2_id.eq.\(currentUserId.uuidString)")
            .order("last_message_time", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(conversations.count) conversations")
        
        // Fetch user profiles for all participants
        var result: [(conversation: ConversationModel, otherUser: UserProfile)] = []
        
        for conversation in conversations {
            // Determine the other user's ID
            let otherUserId = conversation.participant1Id == currentUserId 
                ? conversation.participant2Id 
                : conversation.participant1Id
            
            // Fetch the other user's profile
            if let userProfile = try? await fetchUserProfile(userId: otherUserId) {
                result.append((conversation: conversation, otherUser: userProfile))
            } else {
                // If we can't fetch the profile, create a placeholder
                let placeholder = UserProfile(
                    id: otherUserId,
                    fullName: "User \(otherUserId.uuidString.prefix(8))",
                    username: nil,
                    avatarUrl: nil,
                    bio: nil
                )
                result.append((conversation: conversation, otherUser: placeholder))
            }
        }
        
        return result
    }
    
    /// Fetch a specific conversation by ID
    func fetchConversation(conversationId: UUID) async throws -> ConversationModel {
        let conversation: ConversationModel = try await client
            .from("conversations")
            .select()
            .eq("id", value: conversationId.uuidString)
            .single()
            .execute()
            .value
        
        return conversation
    }
    
    /// Create or get existing conversation between two users
    func getOrCreateConversation(withUserId userId: UUID) async throws -> ConversationModel {
        guard let currentUserId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Ensure we're not trying to message ourselves
        guard currentUserId != userId else {
            throw NSError(domain: "Messages", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot create conversation with yourself"])
        }
        
        print("🔍 Looking for conversation between:")
        print("  Current user: \(currentUserId.uuidString)")
        print("  Other user: \(userId.uuidString)")
        
        // Check if conversation already exists (check both orderings)
        let existing: [ConversationModel] = try await client
            .from("conversations")
            .select()
            .or("and(participant1_id.eq.\(currentUserId.uuidString),participant2_id.eq.\(userId.uuidString)),and(participant1_id.eq.\(userId.uuidString),participant2_id.eq.\(currentUserId.uuidString))")
            .execute()
            .value
        
        if let conversation = existing.first {
            print("✅ Found existing conversation: \(conversation.id)")
            return conversation
        }
        
        // No existing conversation - create using database function
        print("📝 Creating new conversation via database function...")
        
        // Call PostgreSQL function that handles participant ordering server-side
        struct FunctionParams: Encodable {
            let user1_id: String
            let user2_id: String
        }
        
        let params = FunctionParams(
            user1_id: currentUserId.uuidString,
            user2_id: userId.uuidString
        )
        
        do {
            let created: ConversationModel = try await client
                .rpc("get_or_create_conversation", params: params)
                .single()
                .execute()
                .value
            
            print("✅ Conversation created: \(created.id)")
            return created
        } catch {
            print("❌ RPC call failed: \(error.localizedDescription)")
            print("💡 Make sure you've run create_conversation_function.sql in Supabase")
            throw error
        }
    }
    
    // MARK: - Messages
    
    /// Fetch messages for a specific conversation
    func fetchMessages(conversationId: UUID, limit: Int = 50) async throws -> [Message] {
        let messages: [Message] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return messages.reversed() // Return in chronological order
    }
    
    /// Send a new message
    func sendMessage(conversationId: UUID, content: String, messageType: Message.MessageType = .text) async throws -> Message {
        guard let currentUserId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let newMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
            messageType: messageType,
            isRead: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Insert without expecting a return value
        try await client
            .from("messages")
            .insert(newMessage)
            .execute()
        
        // Update conversation's last message
        try await updateConversationLastMessage(conversationId: conversationId, message: newMessage)
        
        return newMessage
    }
    
    /// Mark messages as read
    func markMessagesAsRead(conversationId: UUID) async throws {
        guard let currentUserId = client.auth.currentUser?.id else {
            throw NSError(domain: "Auth", code: 401)
        }
        
        // Mark all unread messages in this conversation that were sent by the other user
        try await client
            .from("messages")
            .update(["is_read": true])
            .eq("conversation_id", value: conversationId.uuidString)
            .neq("sender_id", value: currentUserId.uuidString)
            .eq("is_read", value: false)
            .execute()
        
        // Reset unread count for this conversation
        try await client
            .from("conversations")
            .update(["unread_count": 0])
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
    
    // MARK: - User Profiles
    
    /// Fetch user profile
    func fetchUserProfile(userId: UUID) async throws -> UserProfile {
        let profile: UserProfile = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    /// Search users by name or username
    func searchUsers(query: String) async throws -> [UserProfile] {
        guard !query.isEmpty else { return [] }
        
        let profiles: [UserProfile] = try await client
            .from("profiles")
            .select()
            .or("full_name.ilike.%\(query)%,username.ilike.%\(query)%")
            .limit(20)
            .execute()
            .value
        
        return profiles
    }
    
    // MARK: - Private Helpers
    
    private func updateConversationLastMessage(conversationId: UUID, message: Message) async throws {
        try await client
            .from("conversations")
            .update([
                "last_message_id": message.id.uuidString,
                "last_message_content": message.content,
                "last_message_time": ISO8601DateFormatter().string(from: message.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
}
