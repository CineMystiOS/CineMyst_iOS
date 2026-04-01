//
//  FlicksService.swift
//  CineMystApp
//
//  Supabase service for Flicks/Reels
//

import Foundation
import Supabase

// MARK: - Flick Model
struct Flick: Codable, Identifiable {
    let id: String
    let userId: String
    let videoUrl: String
    let thumbnailUrl: String?
    let caption: String?
    let audioTitle: String?
    let likesCount: Int
    var commentsCount: Int
    let sharesCount: Int
    let createdAt: String
    
    // User info (joined from profiles table)
    var username: String?
    var fullName: String?
    var profilePictureUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case caption
        case audioTitle = "audio_title"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case sharesCount = "shares_count"
        case createdAt = "created_at"
        case username
        case fullName = "full_name"
        case profilePictureUrl = "profile_picture_url"
    }
}

// MARK: - Flick Comment Model
struct FlickComment: Codable, Identifiable {
    let id: String
    let flickId: String
    let userId: String
    let comment: String
    let createdAt: String
    
    // User info
    var username: String?
    var profilePictureUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case flickId = "flick_id"
        case userId = "user_id"
        case comment
        case createdAt = "created_at"
        case username
        case profilePictureUrl = "profile_picture_url"
    }
}

// MARK: - Flick Like Model
struct FlickLike: Codable {
    let flickId: String
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case flickId = "flick_id"
        case userId = "user_id"
    }
}

// MARK: - Flicks Service
class FlicksService {
    static let shared = FlicksService()
    
    private init() {}
    
    // MARK: - Fetch Flicks
    func fetchFlicks(limit: Int = 10, offset: Int = 0) async throws -> [Flick] {
        // Simple select — no FK join needed (flicks.user_id has no declared FK constraint)
        let response = try await supabase
            .from("flicks")
            .select("*")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()

        var flicks = try JSONDecoder().decode([Flick].self, from: response.data)

        // Enrich each flick with profile info via separate lookup
        for i in flicks.indices {
            let uid = flicks[i].userId
            if let profileData = try? await supabase
                .from("profiles")
                .select("username, full_name, profile_picture_url")
                .eq("id", value: uid)
                .single()
                .execute() {
                if let json = try? JSONSerialization.jsonObject(with: profileData.data) as? [String: Any] {
                    flicks[i].username           = json["username"] as? String
                    flicks[i].fullName           = json["full_name"] as? String
                    flicks[i].profilePictureUrl  = json["profile_picture_url"] as? String
                }
            }
            // 2. Fetch accurate comment count
            if let commentsData = try? await supabase
                .from("flick_comments")
                .select("id")
                .eq("flick_id", value: flicks[i].id)
                .execute() {
                if let rows = try? JSONSerialization.jsonObject(with: commentsData.data) as? [[String: Any]] {
                    flicks[i].commentsCount = rows.count
                }
            }
        }

        return flicks
    }
    
    // MARK: - Upload Flick Video
    func uploadFlickVideo(_ videoData: Data, userId: String) async throws -> String {
        let fileName = "\(userId)_\(UUID().uuidString).mov"
        let path = "flicks/\(fileName)"
        
        let _ = try await supabase.storage
            .from("videos")
            .upload(path: path, file: videoData, options: FileOptions(contentType: "video/quicktime"))
        
        // Get public URL
        let publicURL = try supabase.storage
            .from("videos")
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Upload Thumbnail
    func uploadThumbnail(_ imageData: Data, userId: String) async throws -> String {
        let fileName = "\(userId)_\(UUID().uuidString).jpg"
        let path = "thumbnails/\(fileName)"
        
        let _ = try await supabase.storage
            .from("videos")
            .upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        // Get public URL
        let publicURL = try supabase.storage
            .from("videos")
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Create Flick
    func createFlick(videoUrl: String, thumbnailUrl: String?, caption: String?, audioTitle: String?) async throws -> Flick {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            throw NSError(domain: "FlicksService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        struct NewFlick: Encodable {
            let user_id: String
            let video_url: String
            let thumbnail_url: String?
            let caption: String?
            let audio_title: String
            let likes_count: Int
            let comments_count: Int
            let shares_count: Int
        }
        
        let newFlick = NewFlick(
            user_id: userId,
            video_url: videoUrl,
            thumbnail_url: thumbnailUrl,
            caption: caption,
            audio_title: audioTitle ?? "Original Audio",
            likes_count: 0,
            comments_count: 0,
            shares_count: 0
        )
        
        let response = try await supabase
            .from("flicks")
            .insert(newFlick)
            .select()
            .single()
            .execute()
        
        return try JSONDecoder().decode(Flick.self, from: response.data)
    }
    
    // MARK: - Like/Unlike Flick
    func toggleLike(flickId: String) async throws -> Bool {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            throw NSError(domain: "FlicksService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if already liked
        let existingLike = try await supabase
            .from("flick_likes")
            .select()
            .eq("flick_id", value: flickId)
            .eq("user_id", value: userId)
            .execute()
        
        if existingLike.data.isEmpty {
            // Add like
            struct NewLike: Encodable {
                let flick_id: String
                let user_id: String
            }
            
            let like = NewLike(
                flick_id: flickId,
                user_id: userId
            )
            
            try await supabase
                .from("flick_likes")
                .insert(like)
                .execute()
            
            // Increment likes count
            try await supabase
                .rpc("increment_flick_likes", params: ["flick_id": flickId])
                .execute()
            
            return true
        } else {
            // Remove like
            try await supabase
                .from("flick_likes")
                .delete()
                .eq("flick_id", value: flickId)
                .eq("user_id", value: userId)
                .execute()
            
            // Decrement likes count
            try await supabase
                .rpc("decrement_flick_likes", params: ["flick_id": flickId])
                .execute()
            
            return false
        }
    }
    
    // MARK: - Like Flick
    func likeFlick(flickId: String) async throws {
        let userId = try await supabase.auth.session.user.id.uuidString
        struct L: Encodable { let flick_id, user_id: String }
        // Insert instead of upsert so we don't trip missing UPDATE privileges in RLS
        do {
            try await supabase
                .from("flick_likes")
                .insert(L(flick_id: flickId, user_id: userId))
                .execute()
        } catch {
            print("Like insert failed (might already be liked): \(error)")
        }
            
        // Graceful increment (doesn't fail the like if the RPC is missing)
        do {
            try await supabase
                .rpc("increment_flick_likes", params: ["p_flick_id": flickId])
                .execute()
        } catch {
            print("RPC increment failed (likely missing on server), but like succeeded: \(error)")
        }
    }

    // MARK: - Unlike Flick
    func unlikeFlick(flickId: String) async throws {
        let userId = try await supabase.auth.session.user.id.uuidString
        try await supabase
            .from("flick_likes")
            .delete()
            .eq("flick_id", value: flickId)
            .eq("user_id",  value: userId)
            .execute()
            
        // Graceful decrement
        do {
            try await supabase
                .rpc("decrement_flick_likes", params: ["p_flick_id": flickId])
                .execute()
        } catch {
            print("RPC decrement failed, but unlike succeeded: \(error)")
        }
    }

    // MARK: - Check if Liked
    func isFlickLiked(flickId: String) async throws -> Bool {
        guard let uid = try? await supabase.auth.session.user.id.uuidString else { return false }
        let res = try await supabase
            .from("flick_likes")
            .select("flick_id")
            .eq("flick_id", value: flickId)
            .eq("user_id",  value: uid)
            .execute()
        // Must decode — raw Data is never empty even for an empty "[]" response
        let rows = (try? JSONSerialization.jsonObject(with: res.data)) as? [[String: Any]]
        return !(rows?.isEmpty ?? true)
    }
    
    // MARK: - Add Comment
    func addComment(flickId: String, comment: String) async throws -> FlickComment {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            throw NSError(domain: "FlicksService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        struct NewComment: Encodable {
            let flick_id: String
            let user_id: String
            let comment: String
        }
        
        let newComment = NewComment(
            flick_id: flickId,
            user_id: userId,
            comment: comment
        )
        
        let response = try await supabase
            .from("flick_comments")
            .insert(newComment)
            .select()
            .single()
            .execute()
        
        // Increment comments count
        try await supabase
            .rpc("increment_flick_comments", params: ["flick_id": flickId])
            .execute()
        
        return try JSONDecoder().decode(FlickComment.self, from: response.data)
    }
    
    // MARK: - Fetch Comments (no FK join)
    func fetchComments(flickId: String) async throws -> [FlickComment] {
        let response = try await supabase
            .from("flick_comments")
            .select("*")
            .eq("flick_id", value: flickId)
            .order("created_at", ascending: false)
            .execute()

        var comments = try JSONDecoder().decode([FlickComment].self, from: response.data)

        // Enrich with profile usernames
        for i in comments.indices {
            let uid = comments[i].userId
            if let pd = try? await supabase
                .from("profiles")
                .select("username, profile_picture_url")
                .eq("id", value: uid)
                .single()
                .execute() {
                if let json = try? JSONSerialization.jsonObject(with: pd.data) as? [String: Any] {
                    comments[i].username           = json["username"] as? String
                    comments[i].profilePictureUrl  = json["profile_picture_url"] as? String
                }
            }
        }
        return comments
    }
    
    // MARK: - Increment Share Count
    func incrementShareCount(flickId: String) async throws {
        try await supabase
            .rpc("increment_flick_shares", params: ["flick_id": flickId])
            .execute()
    }
}
