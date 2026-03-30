//
//  JobBookmark.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation

struct JobBookmark: Codable, Identifiable {
    let id: UUID
    let jobId: UUID
    let actorId: UUID
    let bookmarkedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case jobId = "job_id"
        case actorId = "actor_id"
        case bookmarkedAt = "bookmarked_at"
    }
}
