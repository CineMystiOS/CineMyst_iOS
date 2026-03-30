//
//  AuthManager.swift
//  CineMystApp
//
//  Created by user@50 on 19/11/25.
//

import Foundation
import Supabase
import UIKit
import SafariServices

final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    private var client: SupabaseClient { supabase }

    // MARK: - Sign Up
    func signUp(email: String, password: String, redirectTo: URL? = nil) async throws {
        if let redirect = redirectTo {
            try await client.auth.signUp(email: email, password: password, redirectTo: redirect)
        } else {
            try await client.auth.signUp(email: email, password: password)
        }
    }

    // MARK: - Sign In
    // ✅ FIXED: This method now properly returns nothing (matches old SDK)
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    // MARK: - Passwordless / Magic Link (OTP)
    func signInWithMagicLink(email: String, redirectTo: URL? = nil) async throws {
        if let redirect = redirectTo {
            let redirectURL = URL(string: "cinemyst://auth-callback")
            try await client.auth.signInWithOTP(email: email, redirectTo: redirectURL)
        } else {
            try await client.auth.signInWithOTP(email: email)
        }
    }

    // MARK: - Reset Password (send email)
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Sign Out
    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Current user/session (read-only helpers)
    var currentUser: User? {
        client.auth.currentUser
    }

    func currentSession() async throws -> Session? {
        return try await client.auth.session
    }

    // MARK: - Auth state listening
    private var subscriptionStorage: Any?

    func startListening() {
        Task {
            let subs = await client.auth.onAuthStateChange { event, session in
                NotificationCenter.default.post(name: .authStateChanged,
                                                object: nil,
                                                userInfo: ["event": event, "session": session as Any])
            }
            self.subscriptionStorage = subs
        }
    }

    func stopListening() {
        subscriptionStorage = nil
    }
    
    // MARK: - Profile Picture Upload
    func uploadProfilePicture(_ image: UIImage, userId: UUID) async throws -> String {
        print("📸 Starting profile picture upload...")
        
        // ✅ BETTER: Check session before attempting upload
        guard let session = try await currentSession() else {
            print("❌ No valid session when uploading profile picture")
            throw ProfileError.invalidSession
        }
        
        print("✅ Session valid, user: \(session.user.id)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to compress image")
            throw ProfileError.imageCompressionFailed
        }
        
        print("📦 Image compressed, size: \(imageData.count) bytes")
        
        let fileName = "\(userId.uuidString)/profile.jpg"
        print("📁 Uploading to path: \(fileName)")
        
        do {
            try await client.storage
                .from("profile-pictures")
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            print("✅ Upload successful!")
            
            let publicURL = try client.storage
                .from("profile-pictures")
                .getPublicURL(path: fileName)
            
            print("🔗 Public URL: \(publicURL.absoluteString)")
            
            return publicURL.absoluteString
            
        } catch let error as StorageError {
            print("❌ Storage Error:")
            print("   Status Code: \(error.statusCode ?? "nil")")
            print("   Message: \(error.message)")
            print("   Error: \(error.error ?? "nil")")
            throw error
        } catch {
            print("❌ Unknown Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Save Profile Data
    func saveProfile(_ profileData: ProfileData) async throws {
        print("🚀 Starting saveProfile...")
        
        // ✅ CRITICAL FIX: Retry getting session with a small delay
        var session: Session?
        for attempt in 1...3 {
            print("🔄 Attempt \(attempt) to get session...")
            do {
                session = try await currentSession()
                if session != nil {
                    print("✅ Session found on attempt \(attempt)")
                    break
                }
            } catch {
                print("⚠️ Session attempt \(attempt) failed: \(error)")
            }
            
            if attempt < 3 {
                try await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
            }
        }
        
        guard let validSession = session else {
            print("❌ No session found after 3 attempts")
            throw ProfileError.invalidSession
        }
        
        let userId = validSession.user.id
        let userEmail = validSession.user.email ?? ""
        print("👤 User ID: \(userId)")
        print("📧 Email: \(userEmail)")
        print("🔑 Access Token exists: \(validSession.accessToken.isEmpty == false)")
        
        // Upload profile picture first if exists
        var profilePictureURL: String? = nil
        if let image = profileData.profilePicture {
            print("📸 Uploading profile picture...")
            do {
                profilePictureURL = try await uploadProfilePicture(image, userId: userId)
            } catch {
                print("❌ Profile picture upload failed: \(error)")
                print("⚠️ Continuing without profile picture...")
            }
        } else {
            print("⏭️ No profile picture, skipping upload")
        }
        
        print("💾 Saving profile to database...")
        
        // Use stored username and fullName from signup
        let username = profileData.username ?? userEmail.components(separatedBy: "@").first ?? "user\(Int.random(in: 1000...9999))"
        let fullName = profileData.fullName
        
        // Determine if onboarding is complete (only if role is set)
        let onboardingCompleted = profileData.role != nil
        
        // Format date of birth
        let dateOfBirthStr = profileData.dateOfBirth.map {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: $0)
        }
        
        // Format role (convert to database format: artist or casting_professional)
        let roleStr = profileData.role?.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
        
        // Get current timestamp for lastActiveAt
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())
        
        // Create profile struct for encoding with all new fields
        let profile = ProfileRecordForSave(
            id: userId.uuidString,
            username: username,
            // email: userEmail,
            fullName: fullName,
            dateOfBirth: dateOfBirthStr,
            profilePictureUrl: profilePictureURL,
            avatarUrl: profilePictureURL,
            role: roleStr,
            employmentStatus: profileData.employmentStatus,
            locationState: profileData.locationState,
            postalCode: profileData.postalCode,
            locationCity: profileData.locationCity,
            bio: nil,
            phoneNumber: nil,
            websiteUrl: nil,
            isVerified: false,
            connectionCount: 0,
            onboardingCompleted: onboardingCompleted,
            lastActiveAt: now,
            bannerUrl: nil  // ✅ ADD THIS LINE
        )
        
        do {
            try await client.from("profiles")
                .upsert(profile)
                .execute()
            
            print("✅ Profile saved to database")
            print("   Username: \(username)")
            print("   Full Name: \(fullName ?? "nil")")
            print("   Onboarding Completed: \(onboardingCompleted)")
            print("   Role: \(roleStr ?? "nil")")
        } catch {
            print("❌ Database error saving profile: \(error)")
            throw error
        }
        
        // Save role-specific data
        if profileData.role == .artist {
            print("🎭 Saving artist profile...")
            try await saveArtistProfile(profileData, userId: userId)
        } else if profileData.role == .castingProfessional {
            print("🎬 Saving casting profile...")
            try await saveCastingProfile(profileData, userId: userId)
        }
        
        print("🎉 All profile data saved successfully!")
    }
    
    // MARK: - Private Helper Methods
    private func saveArtistProfile(_ data: ProfileData, userId: UUID) async throws {
        let artistProfile = ArtistProfileRecordForSave(
            id: userId.uuidString,
            primaryRoles: Array(data.primaryRoles),
            careerStage: data.careerStage,
            skills: data.skills,
            travelWilling: data.travelWilling
        )
        
        do {
            try await client.from("artist_profiles")
                .upsert(artistProfile)
                .execute()
            
            print("✅ Artist profile saved")
        } catch {
            print("❌ Error saving artist profile: \(error)")
            throw error
        }
    }
    
    private func saveCastingProfile(_ data: ProfileData, userId: UUID) async throws {
        let castingProfile = CastingProfileRecordForSave(
            id: userId.uuidString,
            specificRole: data.specificRole,
            companyName: data.companyName,
            castingTypes: Array(data.castingTypes),
            castingRadius: data.castingRadius,
            contactPreference: data.contactPreference
        )
        
        do {
            try await client.from("casting_profiles")
                .upsert(castingProfile)
                .execute()
            
            print("✅ Casting profile saved")
        } catch {
            print("❌ Error saving casting profile: \(error)")
            throw error
        }
    }
}

// MARK: - Database Record Structures for SAVING (Encodable only)
struct ProfileRecordForSave: Encodable {
    let id: String
    let username: String?
    let fullName: String?
    let dateOfBirth: String?
    let profilePictureUrl: String?
    let avatarUrl: String?
    let role: String?
    let employmentStatus: String?
    let locationState: String?
    let postalCode: String?
    let locationCity: String?
    let bio: String?
    let phoneNumber: String?
    let websiteUrl: String?
    let isVerified: Bool?
    let connectionCount: Int?
    let onboardingCompleted: Bool?
    let lastActiveAt: String?
    var bannerUrl: String?
    
    enum CodingKeys: String, CodingKey {
            case id
            case username
            case fullName = "full_name"
            case dateOfBirth = "date_of_birth"
            case profilePictureUrl = "profile_picture_url"
            case avatarUrl = "avatar_url"
            case role
            case employmentStatus = "employment_status"
            case locationState = "location_state"
            case postalCode = "postal_code"
            case locationCity = "location_city"
            case bio
            case phoneNumber = "phone_number"
            case websiteUrl = "website_url"
            case isVerified = "is_verified"
            case connectionCount = "connection_count"
            case onboardingCompleted = "onboarding_completed"
            case lastActiveAt = "last_active_at"
            case bannerUrl = "banner_url" // ✅ ADD THIS LINE
        }
    }

struct ArtistProfileRecordForSave: Encodable {
    let id: String
    let primaryRoles: [String]
    let careerStage: String?
    let skills: [String]
    let travelWilling: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case primaryRoles = "primary_roles"
        case careerStage = "career_stage"
        case skills
        case travelWilling = "travel_willing"
    }
}

struct CastingProfileRecordForSave: Encodable {
    let id: String
    let specificRole: String?
    let companyName: String?
    let castingTypes: [String]
    let castingRadius: Int?
    let contactPreference: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case specificRole = "specific_role"
        case companyName = "company_name"
        case castingTypes = "casting_types"
        case castingRadius = "casting_radius"
        case contactPreference = "contact_preference"
    }
}

// MARK: - Database Record Structures for READING (Codable - both encode & decode)
struct ProfileRecord: Codable {
    let id: String
    let username: String?
    let email: String?
    let fullName: String?
    let dateOfBirth: String?
    let profilePictureUrl: String?
    let avatarUrl: String?
    let role: String?
    let employmentStatus: String?
    let locationState: String?
    let postalCode: String?
    let locationCity: String?
    let bio: String?
    let phoneNumber: String?
    let websiteUrl: String?
    let isVerified: Bool?
    let connectionCount: Int?
    let onboardingCompleted: Bool?
    let createdAt: String?
    let updatedAt: String?
    let lastActiveAt: String?
    var bannerUrl: String? // ✅ NEW: Banner image URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case profilePictureUrl = "profile_picture_url"
        case avatarUrl = "avatar_url"
        case role
        case employmentStatus = "employment_status"
        case locationState = "location_state"
        case postalCode = "postal_code"
        case locationCity = "location_city"
        case bio
        case phoneNumber = "phone_number"
        case websiteUrl = "website_url"
        case isVerified = "is_verified"
        case connectionCount = "connection_count"
        case onboardingCompleted = "onboarding_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActiveAt = "last_active_at"
        case bannerUrl = "banner_url" // ✅ NEW
    }
}
   

extension AuthManager {
    func signInWithGoogle(from viewController: UIViewController) {
        print("➡️ Starting Google Sign-In")
        
        Task {
            do {
                // Get the OAuth URL from Supabase
                let url = try await client.auth.getOAuthSignInURL(
                    provider: .google,
                    redirectTo: URL(string: "cinemyst://auth-callback")
                )
                
                print("🌐 Got OAuth URL: \(url)")
                
                // Open Safari on main thread
                await MainActor.run {
                    let safari = SFSafariViewController(url: url)
                    safari.modalPresentationStyle = .overFullScreen
                    viewController.present(safari, animated: true)
                    print("✅ Safari presented")
                }
                
            } catch {
                print("❌ Error getting OAuth URL: \(error)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Sign In Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
}

struct ArtistProfileRecord: Codable {
    let id: String
    let primaryRoles: [String]
    let careerStage: String?
    let skills: [String]
    let experienceYears: String?
    let headshotUrl: String?
    let mediaUrls: [String]?
    let travelWilling: Bool?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case primaryRoles = "primary_roles"
        case careerStage = "career_stage"
        case skills
        case experienceYears = "experience_years"
        case headshotUrl = "headshot_url"
        case mediaUrls = "media_urls"
        case travelWilling = "travel_willing"
        case createdAt = "created_at"
    }
}

struct CastingProfileRecord: Codable {
    let id: String
    let specificRole: String?
    let companyName: String?
    let castingTypes: [String]
    let castingRadius: Int?
    let contactPreference: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case specificRole = "specific_role"
        case companyName = "company_name"
        case castingTypes = "casting_types"
        case castingRadius = "casting_radius"
        case contactPreference = "contact_preference"
        case createdAt = "created_at"
    }
}

// MARK: - Profile Errors
enum ProfileError: Error {
    case imageCompressionFailed
    case invalidSession
    case uploadFailed
    case noProfileFound
}

extension Notification.Name {
    static let authStateChanged = Notification.Name("AuthManager.authStateChanged")
}
