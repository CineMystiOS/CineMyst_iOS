//
//  OnboardingCoordinator.swift
//  CineMystApp
//
//  Created by user@50 on 08/01/26.
//

import SwiftUI

// MARK: - Onboarding Coordinator
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .birthday
    @Published var profileData = ProfileData()
    var isPostLoginFlow: Bool = false  // Flag to indicate if this is post-login onboarding
    
    enum OnboardingStep {
        case birthday
        case roleSelection
        case roleDetails
        case location
        case profilePicture
        case about
    }
    
    func nextStep() {
        switch currentStep {
        case .birthday:
            // If post-login flow, skip role selection and go straight to location
            currentStep = isPostLoginFlow ? .location : .roleSelection
        case .roleSelection:
            currentStep = .roleDetails
        case .roleDetails:
            currentStep = .location
        case .location:
            currentStep = .profilePicture
        case .profilePicture:
            currentStep = .about  // New step for bio/about
        case .about:
            break  // Complete
        }
    }
}

// MARK: - Profile Data Model
struct ProfileData {
    // User identity (from signup)
    var id: String? 
    var username: String?
    var fullName: String?
    
    // Basic information
    var dateOfBirth: Date?
    var role: UserRole?
    var employmentStatus: String?
    
    // Artist-specific fields
    var primaryRoles: Set<String> = []
    var careerStage: String?
    var skills: [String] = []
    var experienceYears: String?
    var travelWilling: Bool = false
    
    // Casting Professional-specific fields
    var specificRole: String?
    var companyName: String?
    var castingTypes: Set<String> = []
    var castingRadius: Int?
    var contactPreference: String?
    
    // Location
    var locationState: String?
    var postalCode: String?
    var locationCity: String?
    
    // Profile picture
    var profilePicture: UIImage?
    
    // About/Bio
    var bio: String?  // New field for about/bio
}

// MARK: - User Role Enum
enum UserRole: String, CaseIterable {
    case artist = "Artist"
    case castingProfessional = "Casting Professional"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .artist:
            return "theatermasks.fill"
        case .castingProfessional:
            return "film.fill"
        }
    }
}
