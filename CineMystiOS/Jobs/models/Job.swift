//
//  Job.swift
//  CineMystApp
//
//  Created by user@55 on 17/01/26.
//
import Foundation
import UIKit

struct Job: Codable, Identifiable {
    let id: UUID
    let directorId: UUID
    let title: String
    let companyName: String
    let location: String
    let ratePerDay: Int
    let jobType: String
    let description: String?
    let requirements: String?
    let referenceMaterialUrl: String?
    let status: JobStatus
    let applicationDeadline: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum JobStatus: String, Codable {
        case active, pending, completed, closed
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, location, description, requirements, status
        case directorId = "director_id"
        case companyName = "company_name"
        case ratePerDay = "rate_per_day"
        case jobType = "job_type"
        case referenceMaterialUrl = "reference_material_url"
        case applicationDeadline = "application_deadline"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Job {
    
    func toJobCardModel(applicationsCount: Int = 0) -> JobCardModel {
        
        // MARK: - Status
        let statusText: String
        let statusColor: UIColor
        
        switch status {
        case .active:
            statusText = "Active"
            statusColor = UIColor(red: 67/255, green: 22/255, blue: 49/255, alpha: 1)
        case .pending:
            statusText = "Pending"
            statusColor = .systemOrange
        case .completed:
            statusText = "Completed"
            statusColor = .systemGreen
        case .closed:
            statusText = "Closed"
            statusColor = .systemRed
        }
        
        return JobCardModel(
            id: id,
            title: title,
            company: companyName,
            location: location,
            rate: "₹\(ratePerDay)/day",
            type: jobType,
            statusText: statusText,
            statusColor: statusColor,
            applicationsCount: applicationsCount
        )
    }
}


extension Job {

    var daysLeftText: String {
        guard let deadline = applicationDeadline else {
            return "No deadline"
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDeadline = calendar.startOfDay(for: deadline)

        let components = calendar.dateComponents(
            [.day],
            from: startOfToday,
            to: startOfDeadline
        )

        let days = components.day ?? 0

        if days <= 0 {
            return "Last day"
        } else {
            return "\(days) days left"
        }
    }
}

