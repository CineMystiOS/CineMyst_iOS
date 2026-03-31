# Profile Data Integration with Supabase

## Overview
The `ActorProfileViewController` now fetches all profile details directly from Supabase in real-time instead of using hardcoded test data.

## Data Fetching Architecture

### ProfileService
Located at: `auth/ProfileService.swift`

**Main Methods:**
1. `fetchUserProfile(userId:)` - Fetch complete profile for a specific user
2. `fetchCurrentUserProfile()` - Fetch current authenticated user's profile
3. `fetchPortfolioDetails(userId:)` - Get portfolio items for display

### Data Models

#### UserProfileData (Combined Result)
```swift
struct UserProfileData {
    let profile: SupabaseProfileData       // Base profile info
    let artistProfile: SupabaseArtistProfileData?  // Artist-specific details
    let projectCount: Int                   // Total portfolio projects
    let rating: Double?                     // Rating (if available)
}
```

#### SupabaseProfileData
Fetched from `profiles` table:
- `id`, `username`, `fullName`, `bio`
- `role`, `email`
- `profilePictureUrl` (from `avatar_url`)
- `bannerUrl`
- `location` (formatted from city/state)
- `isVerified`
- `connectionCount`

#### SupabaseArtistProfileData
Fetched from `artist_profiles` table:
- `primaryRoles` - Array of acting roles
- `skills` - Array of specialties/skills
- `yearsOfExperience` - Career length
- `careerStage` - Current career stage

## Usage in ActorProfileViewController

### Initialization
```swift
// Display specific user's profile
let controller = ActorProfileViewController(userId: userID)

// Display current logged-in user's profile
let controller = ActorProfileViewController()
```

### Data Display Flow
1. **viewDidLoad()** → `loadProfileData()`
2. **loadProfileData()** → Fetches from Supabase via ProfileService
3. **updateUIWithProfileData()** → Updates UI with fetched data
4. Profile card shows: name, username, role, connections, verification badge
5. Stats show: Project count, Rating, Experience
6. About section shows: Bio, Specialties, Location, Experience

### Image Loading
Profile pictures and banners are loaded asynchronously from URLs:
```swift
loadImage(from: profilePictureUrl) { image in
    profileCard.profileImageView.image = image
}
```

## Database Schema Used

### profiles table
```
id, username, full_name, avatar_url, banner_url, bio,
role, email, location_city, location_state,
is_verified, connection_count
```

### artist_profiles table
```
id, primary_roles[], skills[], years_of_experience, career_stage
```

### portfolios table
```
id, user_id, is_primary, ...
```

### portfolio_items table
```
id, portfolio_id, title, year, type, poster_url, ...
```

## Error Handling
- Shows loading indicator during data fetch
- Displays error alert if profile loading fails
- Gracefully handles missing data with defaults

## Performance Considerations
- Fetches user profile, artist profile, and project count in parallel
- Uses Supabase async/await for clean concurrency
- Lazy loads portfolio details only when needed
- Images loaded asynchronously to prevent UI blocking

## Extending the Service

### Add a new field
1. Add to response model (e.g., `ProfileResponse`)
2. Map to `SupabaseProfileData` in `fetchUserProfile()`
3. Access via `profileData.profile.fieldName` in ViewController

### Add ratings
```swift
// In ProfileService
private func fetchRating(userId: UUID) async throws -> Double {
    let ratings: [RatingResponse] = try await supabase
        .from("ratings")
        .select()
        .eq("user_id", value: userId.uuidString)
        .execute()
        .value
    let avg = ratings.map { Double($0.score) }.reduce(0, +) / Double(ratings.count)
    return avg
}
```

## Testing
To test with real data:
1. Make sure you're logged in to Supabase
2. Navigate to a profile or pass a userId
3. Check console for any errors during fetch
4. Verify all fields populate correctly

## Future Enhancements
- [ ] Add rating/review system integration
- [ ] Cache profile data locally
- [ ] Add real-time updates with Supabase subscriptions
- [ ] Implement pagination for gallery items
- [ ] Add social media link verification
