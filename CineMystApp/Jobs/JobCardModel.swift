import UIKit

struct JobCardModel: Equatable {
    let id: UUID
    let title: String
    let company: String
    let location: String
    let rate: String
    let type: String
    let statusText: String
    let statusColor: UIColor
    let applicationsCount: Int

    var isBookmarked: Bool {
            BookmarkManager.shared.isBookmarked(id)
        }
    
    // MARK: - Init
    init(id: UUID = UUID(),
         title: String,
         company: String,
         location: String,
         rate: String,
         type: String,
         statusText: String,
         statusColor: UIColor,
         applicationsCount: Int) {
        
        self.id = id
        self.title = title
        self.company = company
        self.location = location
        self.rate = rate
        self.type = type
        self.statusText = statusText
        self.statusColor = statusColor
        self.applicationsCount = applicationsCount
    }

    // MARK: - Seeds
    static let activeSeed: [JobCardModel] = [
        .init(
            title: "Lead Actor - City of Dreams",
            company: "YRF Casting",
            location: "Mumbai, India",
            rate: "₹5k/day",
            type: "Series Regular",
            statusText: "Active",
            statusColor: UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1),
            applicationsCount: 6
        )
    ]

    static let pendingSeed: [JobCardModel] = [
        .init(
            title: "Lead Actor - Film Project",
            company: "Netflix India",
            location: "Mumbai, India",
            rate: "₹10k/day",
            type: "Feature Film",
            statusText: "Pending",
            statusColor: .systemOrange,
            applicationsCount: 6
        )
    ]

    static let completedSeed: [JobCardModel] = [
        .init(
            title: "Lead Actor - Crime Web Series",
            company: "Hotstar Originals",
            location: "Goa, India",
            rate: "₹8k/day",
            type: "Web Series",
            statusText: "Completed",
            statusColor: .systemGreen,
            applicationsCount: 6
        )
    ]
}

