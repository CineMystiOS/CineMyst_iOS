// SessionStore.swift
// Stores sessions in memory & notifies listeners when sessions change

import Foundation

// Use a single canonical notification name, keep an alias for backwards-compatibility
extension Notification.Name {
    static let sessionUpdated = Notification.Name("SessionStore.sessionUpdated")
    static let sessionCreated = sessionUpdated   // alias — safe for old code that uses .sessionCreated
}

final class SessionStore {
    static let shared = SessionStore()

    // stored sessions (readable from outside, mutated only via API below)
    private(set) var sessions: [SessionM] = []

    private init() {}

    /// Add a new session (latest first)
    func add(_ session: SessionM) {
        sessions.insert(session, at: 0)
        NotificationCenter.default.post(name: .sessionUpdated, object: nil, userInfo: ["added": session])
        print("[SessionStore] added session id=\(session.id) mentor=\(session.mentorName) date=\(session.date) image=\(session.mentorImageName)")
    }

    /// Remove a session by id (safe mutation API)
    func remove(id: String) {
        let before = sessions.count
        sessions.removeAll { $0.id == id }
        let after = sessions.count
        if before != after {
            NotificationCenter.default.post(name: .sessionUpdated, object: nil, userInfo: ["removedId": id])
            print("[SessionStore] removed session id=\(id) (before=\(before) after=\(after))")
        } else {
            print("[SessionStore] remove called for id=\(id) but nothing removed")
        }
    }

    /// Return a copy of all sessions
    func all() -> [SessionM] {
        return sessions
    }

    /// Clear all sessions
    func clear() {
        sessions.removeAll()
        NotificationCenter.default.post(name: .sessionUpdated, object: nil, userInfo: nil)
        print("[SessionStore] cleared all sessions")
    }
}
