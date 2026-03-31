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
    let mentorImageName: String
    let mentorImageURL: String?
    let mentorshipArea: String?
    let scheduledTimeText: String?

    init(id: String,
         mentorId: String,
         mentorName: String,
         mentorRole: String?,
         date: Date,
         createdAt: Date,
         mentorImageName: String,
         mentorImageURL: String? = nil,
         mentorshipArea: String? = nil,
         scheduledTimeText: String? = nil) {
        self.id = id
        self.mentorId = mentorId
        self.mentorName = mentorName
        self.mentorRole = mentorRole
        self.date = date
        self.createdAt = createdAt
        self.mentorImageName = mentorImageName
        self.mentorImageURL = mentorImageURL
        self.mentorshipArea = mentorshipArea
        self.scheduledTimeText = scheduledTimeText
    }
}
