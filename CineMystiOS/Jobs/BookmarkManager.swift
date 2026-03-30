import Foundation

final class BookmarkManager {

    static let shared = BookmarkManager()

    private let key = "BOOKMARKED_JOB_IDS"
    private var ids: Set<UUID> = []

    private init() {
        load()
    }

    private func load() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            ids = Set(saved.compactMap { UUID(uuidString: $0) })
        }
    }

    private func save() {
        let array = ids.map { $0.uuidString }
        UserDefaults.standard.set(array, forKey: key)
    }

    // MARK: - Public API

    func isBookmarked(_ id: UUID) -> Bool {
        return ids.contains(id)
    }

    /// Returns new bookmark status (true = saved)
    func toggle(_ id: UUID) -> Bool {
        if ids.contains(id) {
            ids.remove(id)
            save()
            return false
        } else {
            ids.insert(id)
            save()
            return true
        }
    }

    func allBookmarkedIDs() -> [UUID] {
        return Array(ids)
    }
}

