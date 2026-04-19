import Foundation
import Supabase

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func fetchUnreadCount() async throws -> Int {
        guard let userId = supabase.auth.currentUser?.id else { return 0 }
        
        // head: true only returns the count if count: .exact is specified
        let response = try await supabase
            .from("notifications")
            .select("*", head: true, count: .exact)
            .eq("recipient_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
            
        return response.count ?? 0
    }

    func subscribeToNotificationChanges(onChange: @escaping @MainActor () -> Void) -> MessagesRealtimeSubscription {
        let realtime = supabase.realtimeV2
        let channel = realtime.channel("notifications:unread_count")

        let listeningTask = Task {
            let stream = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "notifications"
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
    
    func markAllAsRead() async throws {
        guard let userId = supabase.auth.currentUser?.id else { return }
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("recipient_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
}
