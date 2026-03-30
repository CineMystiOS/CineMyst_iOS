// SessionM.swift
// Lightweight session model used by SessionStore and view controllers

import Foundation

struct SessionM: Codable {
    let id: String
    let mentorId: String
    let mentorName: String
    let mentorRole: String?
    let date: Date
    let createdAt: Date
    let mentorImageName: String    // new: image asset name for the mentor
}
