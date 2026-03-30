//
//  Application.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation

struct Application: Codable, Identifiable {
    let id: UUID
    let jobId: UUID
    let actorId: UUID
    let status: ApplicationStatus
    let portfolioUrl: String?
    let portfolioSubmittedAt: Date?
    let appliedAt: Date
    let updatedAt: Date
    
    enum ApplicationStatus: String, Codable {
        case portfolioSubmitted = "portfolio_submitted"
        case taskSubmitted = "task_submitted"
        case shortlisted
        case selected
        case rejected
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case jobId = "job_id"
        case actorId = "actor_id"
        case portfolioUrl = "portfolio_url"
        case portfolioSubmittedAt = "portfolio_submitted_at"
        case appliedAt = "applied_at"
        case updatedAt = "updated_at"
    }
}
