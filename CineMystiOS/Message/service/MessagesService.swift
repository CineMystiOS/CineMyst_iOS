//
//  MessagesService.swift
//  CineMystApp
//
//  Created by AI Assistant
//

import Foundation
import Supabase

final class MessagesRealtimeSubscription {
    private let listeningTask: Task<Void, Never>
    private let removeChannel: @Sendable () async -> Void

    init(
        listeningTask: Task<Void, Never>,
        removeChannel: @escaping @Sendable () async -> Void
    ) {
        self.listeningTask = listeningTask
        self.removeChannel = removeChannel
    }

    func cancel() {
        listeningTask.cancel()
        Task { [removeChannel] in
            await removeChannel()
        }
    }
}

class MessagesService {
    static let shared = MessagesService()
    
    // Use the global supabase instance defined in auth/Supabase.swift
    private var client: SupabaseClient { supabase }
    
    private init() {}

    private struct CreateConversationPayload: Encodable {
        let id: UUID
        let participant1_id: UUID
        let participant2_id: UUID
        let unread_count: Int
        let created_at: String
        let updated_at: String
    }

    private struct ConversationIdRow: Decodable {
        let id: UUID
        let unread_count: Int?
    }

    private struct ConversationLastMessageUpdate: Encodable {
        let last_message_id: String
        let last_message_content: String
        let last_message_time: String
        let unread_count: Int
        let updated_at: String
    }

    private lazy var realtimeDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let iso8601WithFractional = ISO8601DateFormatter()
        iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = iso8601WithFractional.date(from: value) ?? iso8601.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(value)")
        }
        return decoder
    }()
    
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

        // Fetch real unread counts grouping by conversation_id
        struct UnreadMessageRow: Decodable {
            let conversation_id: UUID
        }

        let unreadRows: [UnreadMessageRow]? = try? await client
            .from("messages")
            .select("conversation_id")
            .eq("is_read", value: false)
            .neq("sender_id", value: currentUserId.uuidString)
            .execute()
            .value

        var actualUnreadCounts: [UUID: Int] = [:]
        if let rows = unreadRows {
            for row in rows {
                actualUnreadCounts[row.conversation_id, default: 0] += 1
            }
        }
        
        // Fetch user profiles for all participants
        var result: [(conversation: ConversationModel, otherUser: UserProfile)] = []
        
        for conversation in conversations {
            // Determine the other user's ID
            let otherUserId = conversation.participant1Id == currentUserId 
                ? conversation.participant2Id 
                : conversation.participant1Id
            
            var updatedConversation = conversation
            updatedConversation.unreadCount = actualUnreadCounts[conversation.id] ?? 0

            // Fetch the other user's profile
            if let userProfile = try? await fetchUserProfile(userId: otherUserId) {
                result.append((conversation: updatedConversation, otherUser: userProfile))
            } else {
                // If we can't fetch the profile, create a placeholder
                let placeholder = UserProfile(
                    id: otherUserId,
                    fullName: "User \(otherUserId.uuidString.prefix(8))",
                    username: nil,
                    avatarUrl: nil,
                    bio: nil
                )
                result.append((conversation: updatedConversation, otherUser: placeholder))
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
            print("↩️ Falling back to direct conversation insert")
            return try await createConversationDirectly(currentUserId: currentUserId, otherUserId: userId)
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

    func subscribeToMessages(
        conversationId: UUID,
        onInsert: @escaping @MainActor (Message) -> Void
    ) -> MessagesRealtimeSubscription {
        let realtime = client.realtimeV2
        let channel = realtime.channel("messages:\(conversationId.uuidString)")

        let listeningTask = Task {
            let stream = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages",
                filter: .eq("conversation_id", value: conversationId.uuidString)
            )

            await channel.subscribe()

            for await action in stream {
                guard !Task.isCancelled else { break }
                do {
                    let message = try action.decodeRecord(as: Message.self, decoder: realtimeDecoder)
                    await onInsert(message)
                } catch {
                    print("❌ Failed to decode realtime message: \(error)")
                }
            }
        }

        return MessagesRealtimeSubscription(
            listeningTask: listeningTask,
            removeChannel: {
                await realtime.removeChannel(channel)
            }
        )
    }

    func subscribeToConversationChanges(
        onChange: @escaping @MainActor () -> Void
    ) -> MessagesRealtimeSubscription {
        let realtime = client.realtimeV2
        let channel = realtime.channel("conversations:list")

        let listeningTask = Task {
            let stream = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "conversations"
            )

            await channel.subscribe()

            for await _ in stream {
                guard !Task.isCancelled else { break }
                await onChange()
            }
        }

        return MessagesRealtimeSubscription(
            listeningTask: listeningTask,
            removeChannel: {
                await realtime.removeChannel(channel)
            }
        )
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
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let wildcardQuery = trimmedQuery.replacingOccurrences(of: " ", with: "%")
        let currentUserId = client.auth.currentUser?.id

        let profiles: [UserProfile] = try await client
            .from("profiles")
            .select()
            .or("full_name.ilike.%\(wildcardQuery)%,username.ilike.%\(trimmedQuery)%")
            .limit(20)
            .execute()
            .value

        let filteredProfiles = profiles.filter { profile in
            profile.id != currentUserId
        }

        return filteredProfiles.sorted { lhs, rhs in
            let lhsPrimary = (lhs.fullName ?? lhs.username ?? "").lowercased()
            let rhsPrimary = (rhs.fullName ?? rhs.username ?? "").lowercased()
            let normalizedQuery = trimmedQuery.lowercased()

            let lhsStarts = lhsPrimary.hasPrefix(normalizedQuery)
            let rhsStarts = rhsPrimary.hasPrefix(normalizedQuery)
            if lhsStarts != rhsStarts { return lhsStarts }

            let lhsUsername = (lhs.username ?? "").lowercased()
            let rhsUsername = (rhs.username ?? "").lowercased()
            let lhsUsernameStarts = lhsUsername.hasPrefix(normalizedQuery)
            let rhsUsernameStarts = rhsUsername.hasPrefix(normalizedQuery)
            if lhsUsernameStarts != rhsUsernameStarts { return lhsUsernameStarts }

            return lhsPrimary < rhsPrimary
        }
    }

    func fetchUnreadMessageCount() async throws -> Int {
        guard let currentUserId = client.auth.currentUser?.id else { return 0 }

        do {
            // First, fetch the IDs of conversations this user is a part of
            let conversations: [ConversationIdRow] = try await client
                .from("conversations")
                .select("id")
                .or("participant1_id.eq.\(currentUserId.uuidString),participant2_id.eq.\(currentUserId.uuidString)")
                .execute()
                .value
            
            let conversationIds = conversations.map { $0.id.uuidString }
            guard !conversationIds.isEmpty else { return 0 }

            // Then, count exact unread messages belonging ONLY to those conversations
            let response = try await client
                .from("messages")
                .select("id", head: true, count: .exact)
                .eq("is_read", value: false)
                .neq("sender_id", value: currentUserId.uuidString)
                .in("conversation_id", values: Array(conversationIds))
                .execute()
                
            return response.count ?? 0
        } catch {
            print("❌ Cannot fetch unread messages count directly: \(error)")
            return 0
        }
    }
    
    // MARK: - Private Helpers

    private func createConversationDirectly(currentUserId: UUID, otherUserId: UUID) async throws -> ConversationModel {
        let orderedParticipants = [currentUserId, otherUserId].sorted { $0.uuidString < $1.uuidString }
        let now = ISO8601DateFormatter().string(from: Date())

        let payload = CreateConversationPayload(
            id: UUID(),
            participant1_id: orderedParticipants[0],
            participant2_id: orderedParticipants[1],
            unread_count: 0,
            created_at: now,
            updated_at: now
        )

        do {
            let created: ConversationModel = try await client
                .from("conversations")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            print("✅ Conversation created directly: \(created.id)")
            return created
        } catch {
            print("⚠️ Direct insert failed, checking if conversation was created concurrently: \(error.localizedDescription)")

            let existing: [ConversationModel] = try await client
                .from("conversations")
                .select()
                .or("and(participant1_id.eq.\(orderedParticipants[0].uuidString),participant2_id.eq.\(orderedParticipants[1].uuidString)),and(participant1_id.eq.\(orderedParticipants[1].uuidString),participant2_id.eq.\(orderedParticipants[0].uuidString))")
                .limit(1)
                .execute()
                .value

            if let conversation = existing.first {
                print("✅ Using concurrently created conversation: \(conversation.id)")
                return conversation
            }

            throw error
        }
    }
    
    private func updateConversationLastMessage(conversationId: UUID, message: Message) async throws {
        let existingConversation: ConversationModel = try await client
            .from("conversations")
            .select()
            .eq("id", value: conversationId.uuidString)
            .single()
            .execute()
            .value

        let payload = ConversationLastMessageUpdate(
            last_message_id: message.id.uuidString,
            last_message_content: message.content,
            last_message_time: ISO8601DateFormatter().string(from: message.createdAt),
            unread_count: existingConversation.unreadCount + 1,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await client
            .from("conversations")
            .update(payload)
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
}
