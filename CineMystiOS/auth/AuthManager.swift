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
import AuthenticationServices

// MARK: - Profile Errors
enum ProfileError: Error {
    case imageCompressionFailed
    case invalidSession
    case uploadFailed
    case noProfileFound
}

// MARK: - Batch Password Reset Result
struct PasswordResetBatchResult {
    let successCount: Int
    let failedEmails: [(email: String, error: String)]
    let errorMessage: String?
    
    var isFullSuccess: Bool {
        errorMessage == nil && failedEmails.isEmpty
    }
    
    var summary: String {
        if isFullSuccess {
            return "✅ Successfully sent \(successCount) password reset emails"
        } else if let error = errorMessage {
            return "❌ Error: \(error)"
        } else {
            return "⚠️ Mixed results: \(successCount) succeeded, \(failedEmails.count) failed"
        }
    }
}

final class AuthManager: NSObject {
    static let shared = AuthManager()
    private override init() {}

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
    
    // MARK: - Delete Account
    /// Permanently deletes the user and all their data using a secure RPC
    func deleteAccount() async throws {
        print("🗑️ Attempting to delete account...")
        
        // 1. Call the RPC function we created in Supabase
        try await client.rpc("delete_own_user").execute()
        
        // 2. Sign out locally
        try await signOut()
        
        print("✅ Account deleted and signed out successfully")
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
            fullName: nil,
            role: data.specificRole,
            phoneNumber: nil,
            emailId: nil,
            location: nil,
            governmentIdUrl: nil,
            selfieUrl: nil,
            pastProjectDetails: nil,
            projectRole: nil,
            productionHouse: data.companyName,
            imdbLink: nil,
            companyName: data.companyName,
            officialWorkEmail: nil,
            linkedinProfile: nil,
            instagramProfile: nil,
            portfolioWebsite: nil,
            guildIdCardUrl: nil,
            guildName: nil,
            membershipNumber: nil,
            membershipExpiry: nil,
            industryReferences: nil,
            castingTypes: Array(data.castingTypes),
            castingRadius: data.castingRadius,
            contactPreference: data.contactPreference,
            status: "pending"
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
    
    // MARK: - Batch Password Reset for Migrated Users
    /// Fetches migrated users from profiles table and sends password reset emails
    /// - Returns: A result containing success count, failed emails, and errors
    func sendPasswordResetForMigratedUsers() async -> PasswordResetBatchResult {
        var successCount = 0
        var failedEmails: [(email: String, error: String)] = []
        
        do {
            print("🔍 Fetching migrated users from profiles table...")
            
            // Step 1: Query profiles table for users where is_migrated is true
            let response = try await client
                .from("profiles")
                .select("id, email")
                .eq("is_migrated", value: true)
                .execute()
            
            guard let profiles = response.data as? [[String: Any]] else {
                let error = "Failed to decode profiles response"
                print("❌ \(error)")
                return PasswordResetBatchResult(
                    successCount: 0,
                    failedEmails: [],
                    errorMessage: error
                )
            }
            
            print("✅ Found \(profiles.count) migrated users")
            
            // Step 2: Extract email addresses
            let emails = profiles.compactMap { profile -> String? in
                guard let email = profile["email"] as? String else {
                    print("⚠️ Profile missing email: \(profile["id"] ?? "unknown")")
                    return nil
                }
                return email
            }
            
            print("📧 Extracted \(emails.count) email addresses")
            
            guard !emails.isEmpty else {
                let warning = "No valid email addresses found in migrated users"
                print("⚠️ \(warning)")
                return PasswordResetBatchResult(
                    successCount: 0,
                    failedEmails: [],
                    errorMessage: warning
                )
            }
            
            // Step 3: Loop through emails and send password reset
            print("📤 Sending password reset emails...")
            for (index, email) in emails.enumerated() {
                do {
                    print("[\(index + 1)/\(emails.count)] 📧 Sending reset email to: \(email)")
                    try await resetPassword(email: email)
                    print("✅ Password reset email sent to: \(email)")
                    successCount += 1
                    
                    // Small delay between requests to avoid rate limiting
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                } catch {
                    let errorMessage = error.localizedDescription
                    print("❌ Failed to send reset email to \(email): \(errorMessage)")
                    failedEmails.append((email: email, error: errorMessage))
                }
            }
            
            print("🎉 Batch complete: \(successCount) succeeded, \(failedEmails.count) failed")
            
            return PasswordResetBatchResult(
                successCount: successCount,
                failedEmails: failedEmails,
                errorMessage: nil
            )
            
        } catch let error as DecodingError {
            let message = "Failed to parse profiles response: \(error.localizedDescription)"
            print("❌ \(message)")
            return PasswordResetBatchResult(
                successCount: 0,
                failedEmails: [],
                errorMessage: message
            )
        } catch {
            let message = "Error fetching migrated users: \(error.localizedDescription)"
            print("❌ \(message)")
            return PasswordResetBatchResult(
                successCount: 0,
                failedEmails: [],
                errorMessage: message
            )
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
    let fullName: String?
    let role: String?
    let phoneNumber: String?
    let emailId: String?
    let location: String?
    let governmentIdUrl: String?
    let selfieUrl: String?
    let pastProjectDetails: String?
    let projectRole: String?
    let productionHouse: String?
    let imdbLink: String?
    let companyName: String?
    let officialWorkEmail: String?
    let linkedinProfile: String?
    let instagramProfile: String?
    let portfolioWebsite: String?
    let guildIdCardUrl: String?
    let guildName: String?
    let membershipNumber: String?
    let membershipExpiry: String?
    let industryReferences: String?
    let castingTypes: [String]?
    let castingRadius: Int?
    let contactPreference: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case role
        case phoneNumber = "phone_number"
        case emailId = "email_id"
        case location
        case governmentIdUrl = "government_id_url"
        case selfieUrl = "selfie_url"
        case pastProjectDetails = "past_project_details"
        case projectRole = "project_role"
        case productionHouse = "production_house"
        case imdbLink = "imdb_link"
        case companyName = "company_name"
        case officialWorkEmail = "official_work_email"
        case linkedinProfile = "linkedin_profile"
        case instagramProfile = "instagram_profile"
        case portfolioWebsite = "portfolio_website"
        case guildIdCardUrl = "guild_id_card_url"
        case guildName = "guild_name"
        case membershipNumber = "membership_number"
        case membershipExpiry = "membership_expiry"
        case industryReferences = "industry_references"
        case castingTypes = "casting_types"
        case castingRadius = "casting_radius"
        case contactPreference = "contact_preference"
        case status
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
        let redirectURL = "cinemyst://auth-callback"
        
        Task {
            do {
                // Get the OAuth URL from Supabase
                let url = try await client.auth.getOAuthSignInURL(
                    provider: .google,
                    redirectTo: URL(string: redirectURL)
                )
                
                print("🌐 Got OAuth URL: \(url.absoluteString)")
                
                // Use ASWebAuthenticationSession for better redirect handling
                await MainActor.run {
                    let session = ASWebAuthenticationSession(
                        url: url,
                        callbackURLScheme: "cinemyst"
                    ) { callbackURL, error in
                        if let error = error {
                            print("❌ WebAuth Session error: \(error.localizedDescription)")
                            // Ignore user cancellation
                            if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                                self.handleAuthErrorInVC(viewController, error: error)
                            }
                            return
                        }
                        
                        guard let callbackURL = callbackURL else {
                            print("❌ No callback URL received")
                            return
                        }
                        
                        print("✅ Received callback URL: \(callbackURL.absoluteString)")
                        
                        // Handle the callback
                        Task {
                            do {
                                try await self.client.auth.handle(callbackURL)
                                print("✅ OAuth handled successfully")
                            } catch {
                                print("❌ Error handling OAuth: \(error.localizedDescription)")
                                self.handleAuthErrorInVC(viewController, error: error)
                            }
                        }
                    }
                    
                    session.presentationContextProvider = viewController as? ASWebAuthenticationPresentationContextProviding ?? self
                    session.start()
                    print("🚀 ASWebAuthenticationSession started")
                }
                
            } catch {
                print("❌ Error getting OAuth URL: \(error.localizedDescription)")
                handleAuthErrorInVC(viewController, error: error)
            }
        }
    }
    
    private func handleAuthErrorInVC(_ vc: UIViewController, error: Error) {
        Task { @MainActor in
            let alert = UIAlertController(
                title: "Sign In Error",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            vc.present(alert, animated: true)
        }
    }
}

extension AuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .filter({ $0.isKeyWindow }).first ?? ASPresentationAnchor()
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
    let fullName: String?
    let role: String?
    let phoneNumber: String?
    let emailId: String?
    let location: String?
    let governmentIdUrl: String?
    let selfieUrl: String?
    let pastProjectDetails: String?
    let projectRole: String?
    let productionHouse: String?
    let imdbLink: String?
    let companyName: String?
    let officialWorkEmail: String?
    let linkedinProfile: String?
    let instagramProfile: String?
    let portfolioWebsite: String?
    let guildIdCardUrl: String?
    let guildName: String?
    let membershipNumber: String?
    let membershipExpiry: String?
    let industryReferences: String?
    let castingTypes: [String]?
    let castingRadius: Int?
    let contactPreference: String?
    let status: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case role
        case phoneNumber = "phone_number"
        case emailId = "email_id"
        case location
        case governmentIdUrl = "government_id_url"
        case selfieUrl = "selfie_url"
        case pastProjectDetails = "past_project_details"
        case projectRole = "project_role"
        case productionHouse = "production_house"
        case imdbLink = "imdb_link"
        case companyName = "company_name"
        case officialWorkEmail = "official_work_email"
        case linkedinProfile = "linkedin_profile"
        case instagramProfile = "instagram_profile"
        case portfolioWebsite = "portfolio_website"
        case guildIdCardUrl = "guild_id_card_url"
        case guildName = "guild_name"
        case membershipNumber = "membership_number"
        case membershipExpiry = "membership_expiry"
        case industryReferences = "industry_references"
        case castingTypes = "casting_types"
        case castingRadius = "casting_radius"
        case contactPreference = "contact_preference"
        case status
        case createdAt = "created_at"
    }
}

extension Notification.Name {
    static let authStateChanged = Notification.Name("AuthManager.authStateChanged")
}
