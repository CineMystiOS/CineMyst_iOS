//
//  PortfolioManager.swift
//  CineMystApp
//
//  Created by user@50 on 23/01/26.
//

import Foundation
import Supabase

class PortfolioManager {
    static let shared = PortfolioManager()
    
    // ✅ FIX: Use the global supabase instance
    private var client: SupabaseClient { supabase }
    
    private init() {}
    
    // MARK: - Fetch Portfolio Items
    func fetchPortfolioItems(portfolioId: String) async throws -> [PortfolioItem] {
        print("🔍 Fetching portfolio items for: \(portfolioId)")
        
        let response = try await client
            .from("portfolio_items")
            .select()
            .eq("portfolio_id", value: portfolioId)
            .order("year", ascending: false)
            .order("display_order", ascending: true)
            .execute()
        
        let items = try JSONDecoder().decode([PortfolioItem].self, from: response.data)
        print("✅ Fetched \(items.count) portfolio items")
        
        return items
    }
    
    // MARK: - Add Portfolio Item
    func addPortfolioItem(
        portfolioId: String,
        type: PortfolioItemType,
        year: Int,
        title: String,
        subtitle: String?,
        role: String?,
        productionCompany: String?,
        genre: String?,
        durationMinutes: Int?,
        description: String?,
        posterUrl: String?,
        trailerUrl: String?,
        mediaUrls: [String]?
    ) async throws -> PortfolioItem {
        
        print("📝 Adding portfolio item: \(title)")
        
        // Create encodable struct
        struct PortfolioItemInsert: Encodable {
            let portfolio_id: String
            let type: String
            let year: Int
            let title: String
            let subtitle: String?
            let role: String?
            let production_company: String?
            let genre: String?
            let duration_minutes: Int?
            let description: String?
            let poster_url: String?
            let trailer_url: String?
            let media_urls: [String]?
            let display_order: Int
            let is_featured: Bool
        }
        
        let itemData = PortfolioItemInsert(
            portfolio_id: portfolioId,
            type: type.rawValue,
            year: year,
            title: title,
            subtitle: subtitle,
            role: role,
            production_company: productionCompany,
            genre: genre,
            duration_minutes: durationMinutes,
            description: description,
            poster_url: posterUrl,
            trailer_url: trailerUrl,
            media_urls: mediaUrls,
            display_order: 0,
            is_featured: false
        )
        
        let response = try await client
            .from("portfolio_items")
            .insert(itemData)
            .select()
            .execute()
        
        let items = try JSONDecoder().decode([PortfolioItem].self, from: response.data)
        guard let item = items.first else {
            throw PortfolioError.createFailed
        }
        
        print("✅ Portfolio item added: \(item.id)")
        return item
    }
    
    // MARK: - Update Portfolio Item Title
    func updateItemTitle(itemId: String, title: String) async throws {
        struct TitleUpdate: Encodable {
            let title: String
        }
        
        try await client
            .from("portfolio_items")
            .update(TitleUpdate(title: title))
            .eq("id", value: itemId)
            .execute()
        
        print("✅ Title updated")
    }

    // MARK: - Update Portfolio Item Featured Status
    func updateItemFeatured(itemId: String, isFeatured: Bool) async throws {
        struct FeaturedUpdate: Encodable {
            let is_featured: Bool
        }
        
        try await client
            .from("portfolio_items")
            .update(FeaturedUpdate(is_featured: isFeatured))
            .eq("id", value: itemId)
            .execute()
        
        print("✅ Featured status updated")
    }

    
    // MARK: - Delete Portfolio Item
    func deletePortfolioItem(itemId: String) async throws {
        print("🗑️ Deleting portfolio item: \(itemId)")
        
        try await client
            .from("portfolio_items")
            .delete()
            .eq("id", value: itemId)
            .execute()
        
        print("✅ Portfolio item deleted")
    }
}

// MARK: - Errors
enum PortfolioError: Error, LocalizedError {
    case createFailed
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Failed to create portfolio"
        case .notFound:
            return "Portfolio not found"
        case .invalidData:
            return "Invalid portfolio data"
        }
    }
}
