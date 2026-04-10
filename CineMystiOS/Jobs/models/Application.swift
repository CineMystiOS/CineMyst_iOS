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
    let updatedAt: Date?
    
    enum ApplicationStatus: Codable, Equatable {
        case portfolioSubmitted
        case taskSubmitted
        case shortlisted
        case selected
        case rejected
        case unknown(String)   // ← catches any unrecognised DB value

        var rawValue: String {
            switch self {
            case .portfolioSubmitted: return "portfolio_submitted"
            case .taskSubmitted:      return "task_submitted"
            case .shortlisted:        return "shortlisted"
            case .selected:           return "selected"
            case .rejected:           return "rejected"
            case .unknown(let v):     return v
            }
        }

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            switch raw {
            case "portfolio_submitted": self = .portfolioSubmitted
            case "task_submitted":      self = .taskSubmitted
            case "shortlisted":         self = .shortlisted
            case "selected":            self = .selected
            case "rejected":            self = .rejected
            default:                    self = .unknown(raw)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
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
