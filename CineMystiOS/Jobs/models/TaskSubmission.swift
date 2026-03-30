//
//  TaskSubmission.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation

struct TaskSubmission: Codable, Identifiable {
    let id: UUID
    let applicationId: UUID
    let taskId: UUID
    let actorId: UUID
    let submissionUrl: String
    let submissionType: SubmissionType
    let thumbnailUrl: String?
    let actorNotes: String?
    let status: SubmissionStatus
    let submittedAt: Date
    let reviewedAt: Date?
    
    enum SubmissionType: String, Codable {
        case video, audio, document
    }
    
    enum SubmissionStatus: String, Codable {
        case submitted, reviewed, accepted, rejected
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case applicationId = "application_id"
        case taskId = "task_id"
        case actorId = "actor_id"
        case submissionUrl = "submission_url"
        case submissionType = "submission_type"
        case thumbnailUrl = "thumbnail_url"
        case actorNotes = "actor_notes"
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
    }
}
