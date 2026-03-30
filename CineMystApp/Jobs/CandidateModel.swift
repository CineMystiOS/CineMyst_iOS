import Foundation

struct CandidateModel {
    let applicationId: UUID
    let actorId: UUID
    let name: String
    // If videoURL is provided, use it; otherwise fall back to profile image
    let videoURL: URL?
    let profileImageUrl: String?
    let location: String
    let experience: String
}
