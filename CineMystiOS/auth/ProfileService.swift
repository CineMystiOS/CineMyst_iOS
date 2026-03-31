import Foundation
import Supabase

// MARK: - Profile Data Models

struct SupabaseProfileData {
    let id: UUID
    let username: String?
    let fullName: String?
    let bio: String?
    let role: String?
    let profilePictureUrl: String?
    let bannerUrl: String?
    let location: String?
    let isVerified: Bool
    let connectionCount: Int
    let email: String?
    let phoneNumber: String?
}

struct SupabaseArtistProfileData {
    let primaryRoles: [String]?
    let skills: [String]?
    let yearsOfExperience: Int?
    let careerStage: String?
}

struct UserProfileData {
    let profile: SupabaseProfileData
    let artistProfile: SupabaseArtistProfileData?
    let projectCount: Int
    let rating: Double? // Would need separate table for ratings
}

// MARK: - Profile Service

class ProfileService {
    static let shared = ProfileService()
    
    /// Fetch complete profile data for a user
    func fetchUserProfile(userId: UUID) async throws -> UserProfileData {
        print("🔍 Fetching profile for userId: \(userId.uuidString)")
        
        do {
            // Fetch base profile
            print("📍 Querying profiles table...")
            let profileResponse = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value as ProfileResponse
            
            print("✅ Profile fetched: \(profileResponse.username ?? "unknown")")
            
            let profile = SupabaseProfileData(
                id: UUID(uuidString: profileResponse.id) ?? userId,
                username: profileResponse.username,
                fullName: profileResponse.full_name,
                bio: profileResponse.bio,
                role: profileResponse.role,
                profilePictureUrl: profileResponse.avatar_url ?? profileResponse.profile_picture_url,
                bannerUrl: profileResponse.banner_url,
                location: formatLocation(city: profileResponse.location_city, state: profileResponse.location_state),
                isVerified: profileResponse.is_verified ?? false,
                connectionCount: profileResponse.connection_count ?? 0,
                email: profileResponse.email,
                phoneNumber: profileResponse.phone_number
            )
            
            // Fetch artist profile details
            print("📍 Querying artist_profiles table...")
            let artistProfiles: [ArtistProfileResponse] = try await supabase
                .from("artist_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            print("✅ Artist profiles found: \(artistProfiles.count)")
            
            let artistProfile: SupabaseArtistProfileData?
            if let artistResp = artistProfiles.first {
                artistProfile = SupabaseArtistProfileData(
                    primaryRoles: artistResp.primary_roles,
                    skills: artistResp.skills,
                    yearsOfExperience: artistResp.years_of_experience,
                    careerStage: artistResp.career_stage
                )
            } else {
                artistProfile = nil
            }
            
            // Fetch portfolio items count (projects)
            print("📍 Counting projects...")
            let projectCount = try await getProjectCount(userId: userId)
            print("✅ Projects found: \(projectCount)")
            
            return UserProfileData(
                profile: profile,
                artistProfile: artistProfile,
                projectCount: projectCount,
                rating: nil // Rating would come from a separate ratings table
            )
        } catch {
            print("❌ Error fetching profile: \(error)")
            throw error
        }
    }
    
    /// Fetch current user's profile
    func fetchCurrentUserProfile() async throws -> UserProfileData {
        guard let user = supabase.auth.currentSession?.user else {
            print("❌ User not authenticated")
            throw NSError(domain: "ProfileService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("🔐 Current user ID: \(user.id)")
        return try await fetchUserProfile(userId: user.id)
    }
    
    /// Get project count for a user
    private func getProjectCount(userId: UUID) async throws -> Int {
        do {
            let portfolios: [PortfolioResponse] = try await supabase
                .from("portfolios")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            guard !portfolios.isEmpty else { 
                print("⚠️  No portfolios found for user")
                return 0 
            }
            
            let portfolioIds = portfolios.map { $0.id }
            print("📍 Found \(portfolioIds.count) portfolios")
            
            var count = 0
            for portfolioId in portfolioIds {
                let items: [PortfolioItemResponse] = try await supabase
                    .from("portfolio_items")
                    .select("id")
                    .eq("portfolio_id", value: portfolioId)
                    .execute()
                    .value
                count += items.count
            }
            
            return count
        } catch {
            print("❌ Error fetching project count: \(error)")
            return 0 // Return 0 instead of throwing to avoid breaking profile load
        }
    }
    
    /// Format location from city and state
    private func formatLocation(city: String?, state: String?) -> String? {
        var parts: [String] = []
        if let city = city {
            parts.append(city)
        }
        if let state = state {
            parts.append(state)
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    /// Fetch user's posts with their media (delegates to PostManager which has the joined query)
    func fetchUserPosts(userId: UUID) async throws -> [PostData] {
        do {
            print("📍 Fetching posts for user: \(userId.uuidString)")
            let posts = try await PostManager.shared.fetchUserPosts(userId: userId.uuidString)
            print("✅ Found \(posts.count) posts")

            return posts.map { post in
                let media = post.mediaUrls.map { m in
                    PostMediaData(
                        id: UUID().uuidString,   // PostMedia has no id field
                        postId: post.id,
                        mediaUrl: m.url,
                        mediaType: m.type,
                        thumbnailUrl: m.thumbnailUrl,
                        displayOrder: 0
                    )
                }
                return PostData(
                    id: post.id,
                    userId: post.userId,
                    caption: post.caption,
                    likesCount: post.likesCount,
                    commentsCount: post.commentsCount,
                    sharesCount: post.sharesCount,
                    isPublic: true,
                    createdAt: nil,
                    media: media
                )
            }
        } catch {
            print("❌ Error fetching posts: \(error)")
            return []
        }
    }

    /// Returns true if the user has at least one portfolio row (regardless of items)
    func hasPortfolio(userId: UUID) async -> Bool {
        do {
            let result = try await supabase
                .from("portfolios")
                .select("id", head: true, count: .exact)
                .eq("user_id", value: userId.uuidString)
                .execute()
            let count = result.count ?? 0
            print("📋 Portfolio check: \(count) portfolio(s) found for user")
            return count > 0
        } catch {
            print("⚠️ Portfolio existence check failed: \(error)")
            return false
        }
    }

    /// Fetch portfolio details
    func fetchPortfolioDetails(userId: UUID) async throws -> [PortfolioItemData] {
        do {
            print("📍 Fetching portfolio items for user: \(userId.uuidString)")
            
            let portfolios: [PortfolioResponse] = try await supabase
                .from("portfolios")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            guard let primaryPortfolio = portfolios.first(where: { $0.is_primary ?? false }) ?? portfolios.first else {
                print("⚠️  No portfolios found")
                return []
            }
            
            print("✅ Found portfolio: \(primaryPortfolio.id)")
            
            let items: [PortfolioItemResponse] = try await supabase
                .from("portfolio_items")
                .select()
                .eq("portfolio_id", value: primaryPortfolio.id)
                .order("display_order", ascending: true)
                .execute()
                .value
            
            print("✅ Found \(items.count) portfolio items")
            
            return items.map { item in
                PortfolioItemData(
                    title: item.title,
                    subtitle: item.subtitle,
                    role: item.role,
                    year: item.year,
                    type: item.type,
                    posterUrl: item.poster_url,
                    mediaUrls: item.media_urls
                )
            }
        } catch {
            print("❌ Error fetching portfolio details: \(error)")
            return [] // Return empty instead of throwing to not break profile
        }
    }
}

// MARK: - Response Models (for Supabase)

struct ProfileResponse: Codable {
    let id: String
    let username: String?
    let full_name: String?
    let bio: String?
    let role: String?
    let avatar_url: String?
    let profile_picture_url: String?
    let banner_url: String?
    let location_city: String?
    let location_state: String?
    let is_verified: Bool?
    let connection_count: Int?
    let email: String?
    let phone_number: String?
}

struct ArtistProfileResponse: Codable {
    let id: String
    let primary_roles: [String]?
    let skills: [String]?
    let years_of_experience: Int?
    let career_stage: String?
}

struct PortfolioResponse: Codable {
    let id: String
    let user_id: String
    let stage_name: String?
    let is_primary: Bool?
    let is_public: Bool?
    let instagram_url: String?
    let youtube_url: String?
    let imdb_url: String?
    let twitter_url: String?
    let linkedin_url: String?
    let facebook_url: String?
    let website_url: String?
    let bio: String?
    let profile_picture_url: String?
}

struct PortfolioItemResponse: Codable {
    let id: String
    let portfolio_id: String
    let title: String
    let subtitle: String?
    let role: String?
    let year: Int
    let type: String
    let poster_url: String?
    let trailer_url: String?
    let media_urls: [String]?
    let display_order: Int?
}

struct ConnectionResponse: Codable {
    let id: String
    let requester_id: String?
    let receiver_id: String?
    let status: String?
}

struct PortfolioItemData {
    let title: String
    let subtitle: String?
    let role: String?
    let year: Int
    let type: String
    let posterUrl: String?
    let mediaUrls: [String]?
}

// MARK: - Post Data Models

struct PostData {
    let id: String
    let userId: String
    let caption: String?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let isPublic: Bool
    let createdAt: String?
    let media: [PostMediaData]
}

struct PostMediaData {
    let id: String
    let postId: String
    let mediaUrl: String
    let mediaType: String   // "image" or "video"
    let thumbnailUrl: String?
    let displayOrder: Int
}

// MARK: - Profile Update Struct

struct ProfileUpdate: Encodable {
    let full_name: String
    let bio: String
    let location_city: String
    let location_state: String
    let email: String
    let phone_number: String
    let updated_at: String
    var profile_picture_url: String? = nil
}

struct ArtistProfileUpdate: Encodable {
    let id: String
    let skills: [String]
    let years_of_experience: Int?
}
