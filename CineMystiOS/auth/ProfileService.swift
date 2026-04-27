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
                connectionCount: await fetchConnectionCount(userId: userId),
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
            return 0
        }
    }

    /// Count accepted connections for a user from the connections table
    private func fetchConnectionCount(userId: UUID) async -> Int {
        do {
            let uid = userId.uuidString
            let result = try await supabase
                .from("connections")
                .select("requester_id,receiver_id")
                .eq("status", value: "accepted")
                .or("requester_id.eq.\(uid),receiver_id.eq.\(uid)")
                .execute()

            struct ConnectionPair: Decodable {
                let requesterId: String
                let receiverId: String

                enum CodingKeys: String, CodingKey {
                    case requesterId = "requester_id"
                    case receiverId = "receiver_id"
                }
            }

            let connections = try JSONDecoder().decode([ConnectionPair].self, from: result.data)
            let connectedIds = Set(connections.compactMap { connection in
                let otherId = connection.requesterId == uid ? connection.receiverId : connection.requesterId
                return otherId == uid ? nil : otherId
            })
            let count = connectedIds.count
            print("🔗 Connection count for \(uid.prefix(8)): \(count)")
            return count
        } catch {
            print("⚠️ Failed to fetch connection count: \(error)")
            return 0
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
            // Check new actor_portfolios table first
            let result = try await supabase
                .from("actor_portfolios")
                .select("id", head: true, count: .exact)
                .eq("user_id", value: userId.uuidString)
                .execute()
            if (result.count ?? 0) > 0 { return true }

            // Fall back to legacy portfolios table
            let result2 = try await supabase
                .from("portfolios")
                .select("id", head: true, count: .exact)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return (result2.count ?? 0) > 0
        } catch {
            print("⚠️ Portfolio existence check failed: \(error)")
            return false
        }
    }

    /// Returns "none", "pending", or "connected" between two users
    func connectionState(requesterId: UUID, receiverId: UUID) async -> String {
        do {
            struct ConnRow: Codable { let status: String }
            let mId = requesterId.uuidString
            let oId = receiverId.uuidString
            
            // Fetch all possible rows between these two users
            let rows: [ConnRow] = try await supabase
                .from("connections")
                .select("status")
                .or("and(requester_id.eq.\(mId),receiver_id.eq.\(oId)),and(requester_id.eq.\(oId),receiver_id.eq.\(mId))")
                .execute()
                .value
            
            if rows.contains(where: { $0.status == "accepted" }) {
                return "connected"
            }
            if !rows.isEmpty {
                return "pending"
            }
            return "none"
        } catch {
            print("⚠️ Connection state check failed: \(error)")
            return "none"
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
                    productionCompany: item.production_company,
                    genre: item.genre,
                    durationMinutes: item.duration_minutes,
                    description: item.description,
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
    let full_name: String?   // Safe alias for actor_portfolios
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
    
    // Casting fields (from actor_portfolios)
    let age: String?
    let height_cm: String?
    let weight_kg: String?
    let sex: String?
    let bust: String?
    let waist: String?
    let hips: String?
    let skin_tone: String?
    let eye_color: String?
    let hair_color: String?
    let body_type: String?
    let shoe_size: String?
    let languages: String?
    let contact_no: String?
    let education: String?
    let marital_status: String?
    let current_profession: String?
    let hobbies: String?
    let previous_experience: String?
    let work_interests: [String]?
    let movies: AnyCodable?
    let tvc: AnyCodable?
    let tv_serials: AnyCodable?
    let theatre: AnyCodable?
    let advertisement: AnyCodable?
    let web_series: AnyCodable?
    let media_urls: AnyCodable?
    
    // Helper to get media as dicts
    var mediaItems: [[String: String]] {
        if let array = media_urls?.value as? [[String: String]] {
            return array
        }
        // Fallback for different JSON serialization
        if let anyArray = media_urls?.value as? [[String: Any]] {
            return anyArray.map { dict in
                var newDict: [String: String] = [:]
                for (k, v) in dict { newDict[k] = "\(v)" }
                return newDict
            }
        }
        return []
    }
}

// Simple AnyCodable-like wrapper if not available, or use Any
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a codable value") }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? Bool { try container.encode(x) }
        else if let x = value as? Int { try container.encode(x) }
        else if let x = value as? Double { try container.encode(x) }
        else if let x = value as? String { try container.encode(x) }
        else if let x = value as? [Any] { try container.encode(x.map { AnyCodable($0) }) }
        else if let x = value as? [String: Any] { try container.encode(x.mapValues { AnyCodable($0) }) }
    }
}

struct PortfolioItemResponse: Codable {
    let id: String
    let portfolio_id: String
    let title: String
    let subtitle: String?
    let role: String?
    let year: Int
    let type: String
    let production_company: String?
    let genre: String?
    let duration_minutes: Int?
    let description: String?
    let poster_url: String?
    let trailer_url: String?
    let media_urls: [String]?
    let display_order: Int?
}

// MARK: - Recommendations Service

final class RecommendationsService {
    static let shared = RecommendationsService()

    private let session: URLSession
    private let baseURL: URL

    private init(session: URLSession = .shared) {
        self.session = session
        if let configuredBaseURL = Bundle.main.object(forInfoDictionaryKey: "AI_CHATBOT_BASE_URL") as? String,
           let configuredURL = URL(string: configuredBaseURL),
           !configuredBaseURL.isEmpty {
            self.baseURL = configuredURL
        } else {
            self.baseURL = URL(string: "https://cinemyst-chatbot-backend.onrender.com")!
        }
    }

    func refreshRecommendations(for userId: UUID) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/process-profile/\(userId.uuidString)"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await session.data(for: request)
        try validate(response: response, service: "RecommendationsService")
    }

    func fetchDiscoveryProfiles(for userId: UUID, refreshFirst: Bool = false) async throws -> [DiscoveryProfile] {
        if refreshFirst {
            do {
                try await refreshRecommendations(for: userId)
            } catch {
                // Fall back to the last saved recommendations if refresh fails.
                print("⚠️ Failed to refresh recommendations before fetch: \(error)")
            }
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/recommendations/\(userId.uuidString)"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validate(response: response, service: "RecommendationsService")

        let rawItems = try extractRecommendationItems(from: data)
        let candidates = rawItems.compactMap(Self.parseCandidate(from:))
            .filter { $0.id != userId }

        guard !candidates.isEmpty else { return [] }

        if candidates.allSatisfy({ $0.hasDisplayDetails }) {
            return candidates.map(\.discoveryProfile)
        }

        let hydratedProfilesById = try await hydrateProfiles(ids: candidates.map(\.id))
        return candidates.compactMap { candidate in
            hydratedProfilesById[candidate.id.uuidString] ?? (candidate.hasDisplayDetails ? candidate.discoveryProfile : nil)
        }
    }

    private func hydrateProfiles(ids: [UUID]) async throws -> [String: DiscoveryProfile] {
        var seen = Set<String>()
        let idStrings = ids.map(\.uuidString).filter { seen.insert($0).inserted }
        guard !idStrings.isEmpty else { return [:] }

        let response: [ProfileResponse] = try await supabase
            .from("profiles")
            .select("id, username, full_name, role, avatar_url, profile_picture_url, location_city, location_state")
            .in("id", value: idStrings)
            .execute()
            .value

        return Dictionary(uniqueKeysWithValues: response.compactMap { profile in
            guard let uuid = UUID(uuidString: profile.id) else { return nil }
            return (
                uuid.uuidString,
                DiscoveryProfile(
                    id: uuid,
                    fullName: profile.full_name,
                    username: profile.username,
                    role: profile.role,
                    profilePictureUrl: profile.avatar_url ?? profile.profile_picture_url,
                    location: Self.formatLocation(city: profile.location_city, state: profile.location_state)
                )
            )
        })
    }

    private func validate(response: URLResponse, service: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: service, code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response."])
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw NSError(
                domain: service,
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Request failed with status \(httpResponse.statusCode)."]
            )
        }
    }

    private func extractRecommendationItems(from data: Data) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: data)
        return Self.extractArray(from: object)
    }

    private static func extractArray(from object: Any) -> [[String: Any]] {
        if let array = object as? [[String: Any]] {
            return array
        }

        guard let dict = object as? [String: Any] else {
            return []
        }

        for key in ["recommendations", "results", "items", "data"] {
            if let nested = dict[key] {
                let extracted = extractArray(from: nested)
                if !extracted.isEmpty {
                    return extracted
                }
            }
        }

        return []
    }

    private static func parseCandidate(from item: [String: Any]) -> RecommendationCandidate? {
        let nestedProfile = ["recommended_user", "recommended_profile", "profile", "user", "candidate"]
            .compactMap { item[$0] as? [String: Any] }
            .first

        let source = nestedProfile ?? item
        let idString =
            nonEmptyString(in: source, keys: ["recommended_user_id", "recommendedUserId", "id", "profile_id", "user_id"]) ??
            nonEmptyString(in: item, keys: ["recommended_user_id", "recommendedUserId", "profile_id", "id", "user_id"])

        guard let idString, let id = UUID(uuidString: idString) else {
            return nil
        }

        let city = nonEmptyString(in: source, keys: ["location_city", "city"])
        let state = nonEmptyString(in: source, keys: ["location_state", "state"])
        let location = formatLocation(city: city, state: state) ?? nonEmptyString(in: source, keys: ["location"])

        return RecommendationCandidate(
            id: id,
            fullName: nonEmptyString(in: source, keys: ["full_name", "fullName", "name"]),
            username: nonEmptyString(in: source, keys: ["username", "handle"]),
            role: nonEmptyString(in: source, keys: ["role", "primary_role"]),
            profilePictureUrl: nonEmptyString(in: source, keys: ["profile_picture_url", "profilePictureUrl", "avatar_url", "avatarUrl"]),
            location: location
        )
    }

    private static func nonEmptyString(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            guard let value = dict[key] else { continue }

            if let string = value as? String {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }

            if let number = value as? NSNumber {
                return number.stringValue
            }
        }

        return nil
    }

    private static func formatLocation(city: String?, state: String?) -> String? {
        var components: [String] = []
        if let city, !city.isEmpty { components.append(city) }
        if let state, !state.isEmpty { components.append(state) }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

private struct RecommendationCandidate {
    let id: UUID
    let fullName: String?
    let username: String?
    let role: String?
    let profilePictureUrl: String?
    let location: String?

    var hasDisplayDetails: Bool {
        fullName != nil || username != nil || role != nil || profilePictureUrl != nil || location != nil
    }

    var discoveryProfile: DiscoveryProfile {
        DiscoveryProfile(
            id: id,
            fullName: fullName,
            username: username,
            role: role,
            profilePictureUrl: profilePictureUrl,
            location: location
        )
    }
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
    let productionCompany: String?
    let genre: String?
    let durationMinutes: Int?
    let description: String?
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
