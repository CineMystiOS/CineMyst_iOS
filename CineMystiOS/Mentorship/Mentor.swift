// Mentor.swift
// Shared Mentor model used by multiple view controllers

import Foundation

// Lightweight Mentor model used across the app. Extended to include
// fields we fetch from the backend so the UI can render real data.
struct Mentor {
    let id: String?
    let name: String
    let role: String
    let rating: Double
    let imageName: String?           // local asset fallback
    let profilePictureUrl: String?   // remote image URL from DB
    let ratingCount: Int?            // number of reviews/sessions
    let mentorshipAreas: [String]?   // array of skill/area strings
    let orgName: String?             // organization / company (column `name` in DB)
    let sessionCount: Int?          // column `session` in DB
    let moneyString: String?        // raw money column (if present)
    let about: String?
    let userId: String?
    let metadataJson: String?
    let createdAt: String?
    let priceCents: Int?
    let currency: String?

    init(id: String? = nil,
         name: String,
         role: String,
         rating: Double,
         imageName: String? = "Image",
         profilePictureUrl: String? = nil,
         ratingCount: Int? = nil,
         mentorshipAreas: [String]? = nil,
         orgName: String? = nil,
         sessionCount: Int? = nil,
         moneyString: String? = nil,
         about: String? = nil,
         userId: String? = nil,
         metadataJson: String? = nil,
         createdAt: String? = nil,
         priceCents: Int? = nil,
         currency: String? = nil) {
        self.id = id
        self.name = name
        self.role = role
        self.rating = rating
        self.imageName = imageName
        self.profilePictureUrl = profilePictureUrl
        self.ratingCount = ratingCount
        self.mentorshipAreas = mentorshipAreas
    self.orgName = orgName
    self.sessionCount = sessionCount
    self.moneyString = moneyString
    self.about = about
    self.userId = userId
    self.metadataJson = metadataJson
    self.priceCents = priceCents
    self.currency = currency
    self.createdAt = createdAt
    }
}
