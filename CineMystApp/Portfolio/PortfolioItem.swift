//
//  PortfolioItem.swift
//  CineMystApp
//
//  Created by user@50 on 23/01/26.
//

import Foundation

// MARK: - Portfolio Item (Database Model)
struct PortfolioItem: Codable, Identifiable {
    let id: String
    let portfolioId: String
    let type: PortfolioItemType
    let year: Int
    let title: String
    let subtitle: String?
    let role: String?
    let productionCompany: String?
    let organization: String?
    let location: String?
    let genre: String?
    let durationMinutes: Int?
    let description: String?
    let posterUrl: String?
    let trailerUrl: String?
    let mediaUrls: [String]?
    let displayOrder: Int
    let isFeatured: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId = "portfolio_id"
        case type
        case year
        case title
        case subtitle
        case role
        case productionCompany = "production_company"
        case organization
        case location
        case genre
        case durationMinutes = "duration_minutes"
        case description
        case posterUrl = "poster_url"
        case trailerUrl = "trailer_url"
        case mediaUrls = "media_urls"
        case displayOrder = "display_order"
        case isFeatured = "is_featured"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for display
    var durationText: String {
        guard let minutes = durationMinutes else { return "" }
        return "\(minutes) MIN"
    }
    
    var yearText: String {
        return "\(year)"
    }
}

// MARK: - Portfolio Item Type Enum
enum PortfolioItemType: String, Codable, CaseIterable {
    case film = "film"
    case theatre = "theatre"
    case workshop = "workshop"
    case training = "training"
    case webseries = "webseries"
    case commercial = "commercial"
    case tvShow = "tv_show"
    
    var displayName: String {
        switch self {
        case .film: return "Film"
        case .theatre: return "Theatre"
        case .workshop: return "Workshop"
        case .training: return "Training"
        case .webseries: return "Web Series"
        case .commercial: return "Commercial"
        case .tvShow: return "TV Show"
        }
    }
}

// MARK: - ✅ UI Display Models (for existing cells)
struct PortfolioData {
    let name: String
    let role: String
    let about: String
    let achievements: [String]
    let workshops: [Workshop]
    let films: [Film]
}

struct Workshop {
    let title: String
    let type: String
    let location: String
    let duration: String
}

struct Film {
    let title: String
    let year: String
    let role: String
    let duration: String
    let production: String
    let imageName: String
}

// MARK: - ✅ Extensions to Convert PortfolioItem to UI Models
extension PortfolioItem {
    /// Convert PortfolioItem to Film (for FilmCell)
    func toFilm() -> Film {
        Film(
            title: self.title,
            year: String(self.year),
            role: self.role ?? "Actor",
            duration: self.durationText,
            production: self.productionCompany ?? "",
            imageName: self.posterUrl ?? "placeholder"
        )
    }
    
    /// Convert PortfolioItem to Workshop (for WorkshopCell)
    func toWorkshop() -> Workshop {
        Workshop(
            title: self.title,
            type: self.subtitle ?? self.genre ?? self.type.displayName,
            location: self.location ?? "",
            duration: self.organization ?? "\(self.year)"
        )
    }
}

// MARK: - ✅ Array Extensions for Filtering
extension Array where Element == PortfolioItem {
    /// Get all film-related items
    var films: [Film] {
        self.filter { item in
            item.type == .film || item.type == .tvShow || item.type == .webseries
        }.map { $0.toFilm() }
    }
    
    /// Get all workshop/training items
    var workshops: [Workshop] {
        self.filter { item in
            item.type == .workshop || item.type == .training
        }.map { $0.toWorkshop() }
    }
}
