//
//  PostManager.swift
//  CineMystApp
//
//  Handles all post-related API operations
//

import Foundation
import Supabase
import UIKit

final class PostManager {
    static let shared = PostManager()
    private init() {}
    
    private var client: SupabaseClient { supabase }
    
    // MARK: - Fetch Posts
    func fetchPosts(limit: Int = 50, offset: Int = 0) async throws -> [Post] {
        let response = try await client
            .from("posts")
            .select("""
                id,
                user_id,
                caption,
                likes_count,
                comments_count,
                shares_count,
                created_at,
                profiles(username, profile_picture_url),
                post_media(media_url, media_type, thumbnail_url, width, height, display_order)
            """)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 first
            if let date = try? ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // Try with milliseconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback: try common formats
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        let posts = try decoder.decode([PostResponse].self, from: response.data)
        
        return posts.map { postResponse in
            Post(
                id: postResponse.id,
                userId: postResponse.userId,
                username: postResponse.profiles?.username ?? "Unknown",
                userProfilePictureUrl: postResponse.profiles?.profilePictureUrl,
                caption: postResponse.caption,
                mediaUrls: postResponse.postMedia ?? [],
                likesCount: postResponse.likesCount,
                commentsCount: postResponse.commentsCount,
                sharesCount: postResponse.sharesCount,
                createdAt: postResponse.createdAt
            )
        }
    }
    
    // MARK: - Fetch User Posts (for Profile)
    func fetchUserPosts(userId: String, limit: Int = 50) async throws -> [Post] {
        let response = try await client
            .from("posts")
            .select("""
                id,
                user_id,
                caption,
                likes_count,
                comments_count,
                shares_count,
                created_at,
                profiles(username, profile_picture_url),
                post_media(media_url, media_type, thumbnail_url, width, height, display_order)
            """)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 first
            if let date = try? ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // Try with milliseconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback: try common formats
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        let posts = try decoder.decode([PostResponse].self, from: response.data)
        
        return posts.map { postResponse in
            Post(
                id: postResponse.id,
                userId: postResponse.userId,
                username: postResponse.profiles?.username ?? "Unknown",
                userProfilePictureUrl: postResponse.profiles?.profilePictureUrl,
                caption: postResponse.caption,
                mediaUrls: postResponse.postMedia ?? [],
                likesCount: postResponse.likesCount,
                commentsCount: postResponse.commentsCount,
                sharesCount: postResponse.sharesCount,
                createdAt: postResponse.createdAt
            )
        }
    }
    
    private func fetchUserProfile(userId: String) async throws -> ProfileRecord? {
        let response = try await client
            .from("profiles")
            .select("id, username, profile_picture_url")
            .eq("id", value: userId)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        return try? decoder.decode(ProfileRecord.self, from: response.data)
    }
    
    // MARK: - Create Post
    func createPost(caption: String?, media: [DraftMedia]) async throws -> Post {
        print("📝 Starting post creation...")
        
        guard let session = try await AuthManager.shared.currentSession() else {
            throw PostError.notAuthenticated
        }
        
        let userId = session.user.id
        
        // 1. Upload all media first
        var mediaItems: [(url: String, type: String, thumbnail: String?, width: Int?, height: Int?)] = []
        
        for (index, mediaItem) in media.enumerated() {
            print("📤 Uploading media \(index + 1)/\(media.count)...")
            
            if let image = mediaItem.image {
                let url = try await uploadImage(image, userId: userId, index: index)
                mediaItems.append((
                    url: url,
                    type: "image",
                    thumbnail: url,
                    width: Int(image.size.width),
                    height: Int(image.size.height)
                ))
            } else if let videoURL = mediaItem.videoURL {
                let url = try await uploadVideo(videoURL, userId: userId, index: index)
                mediaItems.append((
                    url: url,
                    type: "video",
                    thumbnail: nil,
                    width: nil,
                    height: nil
                ))
            }
        }
        
        // 2. Create post record - SIMPLIFIED
        struct PostInsert: Encodable {
            let user_id: String
            let caption: String?
        }
        
        let postInsert = PostInsert(
            user_id: userId.uuidString,
            caption: caption
        )
        
        // Insert post and get ID back
        let postResponse = try await client
            .from("posts")
            .insert(postInsert)
            .select("id")  // ← Only select the ID we need
            .single()      // ← Get single record
            .execute()
        
        // Decode just the ID
        struct PostIdResponse: Decodable {
            let id: String
        }
        
        let decoder = JSONDecoder()
        let postIdData = try decoder.decode(PostIdResponse.self, from: postResponse.data)
        let postId = postIdData.id
        
        print("✅ Post created with ID: \(postId)")
        
        // 3. Insert all media records
        if !mediaItems.isEmpty {
            struct MediaInsert: Encodable {
                let post_id: String
                let media_url: String
                let media_type: String
                let thumbnail_url: String?
                let width: Int?
                let height: Int?
                let display_order: Int
            }
            
            let mediaInserts = mediaItems.enumerated().map { index, item in
                MediaInsert(
                    post_id: postId,
                    media_url: item.url,
                    media_type: item.type,
                    thumbnail_url: item.thumbnail,
                    width: item.width,
                    height: item.height,
                    display_order: index
                )
            }
            
            // Insert all media at once (more efficient)
            try await client
                .from("post_media")
                .insert(mediaInserts)
                .execute()
            
            print("✅ Inserted \(mediaItems.count) media items")
        }
        
        // 4. Fetch the complete post with all relations
        return try await fetchCompletePost(postId: postId)
    }
    
    // Helper function to fetch complete post
    private func fetchCompletePost(postId: String) async throws -> Post {
        let response = try await client
            .from("posts")
            .select("""
                id,
                user_id,
                caption,
                likes_count,
                comments_count,
                shares_count,
                created_at,
                profiles(username, profile_picture_url),
                post_media(media_url, media_type, thumbnail_url, width, height, display_order)
            """)
            .eq("id", value: postId)
            .order("display_order", ascending: true, referencedTable: "post_media")
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        // Use the same flexible date decoding strategy as in fetchPosts
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 first
            if let date = try? ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // Try with milliseconds
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            // Fallback: try common formats
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss"
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        
        let postResponse = try decoder.decode(PostResponse.self, from: response.data)
        
        return Post(
            id: postResponse.id,
            userId: postResponse.userId,
            username: postResponse.profiles?.username ?? "Unknown",
            userProfilePictureUrl: postResponse.profiles?.profilePictureUrl,
            caption: postResponse.caption,
            mediaUrls: postResponse.postMedia ?? [],
            likesCount: postResponse.likesCount,
            commentsCount: postResponse.commentsCount,
            sharesCount: postResponse.sharesCount,
            createdAt: postResponse.createdAt
        )
    }
    
    // MARK: - Upload Media
    private func uploadImage(_ image: UIImage, userId: UUID, index: Int) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageCompressionFailed
        }
        
        let fileName = "\(userId.uuidString)/posts/\(UUID().uuidString)_\(index).jpg"
        
        try await client.storage
            .from("post-media")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg"
                )
            )
        
        let publicURL = try client.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    private func uploadVideo(_ videoURL: URL, userId: UUID, index: Int) async throws -> String {
        let videoData = try Data(contentsOf: videoURL)
        let fileName = "\(userId.uuidString)/posts/\(UUID().uuidString)_\(index).mp4"
        
        try await client.storage
            .from("post-media")
            .upload(
                path: fileName,
                file: videoData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "video/mp4"
                )
            )
        
        let publicURL = try client.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Like/Unlike Post
    func likePost(postId: String) async throws {
        // Increment likes count
        try await client.rpc(
            "increment_post_likes",
            params: ["post_id": postId]
        ).execute()
    }
    
    func unlikePost(postId: String) async throws {
        // Decrement likes count
        try await client.rpc(
            "decrement_post_likes",
            params: ["post_id": postId]
        ).execute()
    }
    
    // MARK: - Delete Post
    func deletePost(postId: String) async throws {
        try await client
            .from("posts")
            .delete()
            .eq("id", value: postId)
            .execute()
    }
}

// MARK: - Response Models
struct PostResponse: Codable {
    let id: String
    let userId: String
    let caption: String?
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let createdAt: Date
    let profiles: ProfileData?
    let postMedia: [PostMedia]?
    
    struct ProfileData: Codable {
        let username: String?
        let profilePictureUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case username
            case profilePictureUrl = "profile_picture_url"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case caption
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case sharesCount = "shares_count"
        case createdAt = "created_at"
        case profiles
        case postMedia = "post_media"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try container.decode(String.self, forKey: .id)
            userId = try container.decode(String.self, forKey: .userId)
            caption = try container.decodeIfPresent(String.self, forKey: .caption)
            likesCount = try container.decode(Int.self, forKey: .likesCount)
            commentsCount = try container.decode(Int.self, forKey: .commentsCount)
            sharesCount = try container.decode(Int.self, forKey: .sharesCount)
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            profiles = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
            postMedia = try container.decodeIfPresent([PostMedia].self, forKey: .postMedia)
        } catch {
            print("❌ PostResponse decoding error: \(error)")
            throw error
        }
    }
}

// MARK: - Errors
enum PostError: Error, LocalizedError {
    case notAuthenticated
    case imageCompressionFailed
    case uploadFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to post"
        case .imageCompressionFailed: return "Failed to process image"
        case .uploadFailed: return "Failed to upload media"
        case .invalidData: return "Invalid post data"
        }
    }
}
