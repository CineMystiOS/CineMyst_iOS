//
//  Task.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation

struct JobTask: Codable, Identifiable {
    let id: UUID
    let jobId: UUID
    let taskTitle: String
    let taskDescription: String
    let characterName: String?
    let characterDescription: String?
    let characterAgeRange: String?
    let genre: String?
    let personalityTraits: String?
    let sceneTitle: String?
    let sceneSetting: String?
    let expectedDuration: String?
    let referenceMaterialUrl: String?
    let requirements: [String]?
    let dueDate: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case jobId = "job_id"
        case taskTitle = "task_title"
        case taskDescription = "task_description"
        case characterName = "character_name"
        case characterDescription = "character_description"
        case characterAgeRange = "character_age_range"
        case genre
        case personalityTraits = "personality_traits"
        case sceneTitle = "scene_title"
        case sceneSetting = "scene_setting"
        case expectedDuration = "expected_duration"
        case referenceMaterialUrl = "reference_material_url"
        case requirements
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}
