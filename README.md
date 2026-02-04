# IRONCORE - Fitness Ranking iOS App

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2017.0+-lightgrey.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue.svg)

IRONCORE is a fitness tracking and ranking app that calculates a weekly fitness score from HealthKit data and provides a competitive MMR/LP ranking system. Built with SwiftUI, MVVM architecture, and Neon Database (Auth + Data API).

## Features

- 🔐 **Authentication**: Neon Auth integration (email/password)
- 💪 **HealthKit Integration**: Tracks workouts, active energy, and sleep
- 📊 **Score Calculation**: Weekly fitness score (0-100) based on:
  - Consistency (40 points)
  - Volume (25 points)
  - Intensity (25 points)
  - Recovery (10 points)
- 🏆 **Ranking System**: MMR/LP-based ranking with 10 tiers
- 👥 **Social Features**: Add friends and compete on weekly leaderboard
- 📈 **History**: Track your weekly progress over time
- 🌙 **Dark Mode**: Neon-themed UI with Apple-like design

## Tech Stack

- **Frontend**: SwiftUI, MVVM architecture
- **Concurrency**: async/await
- **Backend**: Neon Database
  - Neon Auth for authentication
  - Neon Data API (PostgREST) for database operations
- **Storage**: Keychain for JWT tokens
- **Health**: HealthKit framework

## Project Structure

```
Iron Core/
├── IronCoreApp.swift              # App entry point
├── ContentView.swift              # Root navigation view
├── Models/
│   ├── User.swift                 # User, Profile, Rating models
│   ├── WeeklyScore.swift         # Score models
│   ├── Friendship.swift          # Friend relationship models
│   └── AuthModels.swift          # Auth request/response models
├── ViewModels/
│   ├── AuthViewModel.swift       # Authentication logic
│   ├── HealthKitViewModel.swift  # HealthKit permissions
│   ├── RankingViewModel.swift    # Score & ranking logic
│   ├── FriendsViewModel.swift    # Friend management
│   ├── LeaderboardViewModel.swift # Leaderboard logic
│   └── HistoryViewModel.swift    # History tracking
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── SignUpView.swift
│   │   ├── SignInView.swift
│   │   └── HealthKitOnboardingView.swift
│   ├── Home/
│   │   └── HomeView.swift         # Main dashboard
│   ├── Leaderboard/
│   │   └── LeaderboardView.swift  # Friend rankings
│   ├── Friends/
│   │   └── FriendsView.swift      # Friend management
│   ├── History/
│   │   └── HistoryView.swift      # Past weeks
│   ├── Settings/
│   │   └── SettingsView.swift     # App settings
│   └── MainTabView.swift          # Tab navigation
├── Services/
│   ├── NeonAuthService.swift      # Neon Auth API client
│   ├── NeonDataAPIClient.swift    # PostgREST client
│   ├── HealthKitManager.swift     # HealthKit operations
│   └── ScoreCalculator.swift      # Score calculation logic
├── Utilities/
│   ├── KeychainStore.swift        # Secure token storage
│   ├── Config.swift               # App configuration
│   └── Extensions.swift           # Helper extensions
└── Database/
    ├── schema.sql                 # Database schema with RLS
    └── test_queries.sql           # Testing queries
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Neon Database account ([neon.tech](https://neon.tech))
- Physical iOS device or simulator with Health app

### 1. Neon Database Setup

#### A. Create Neon Project

1. Go to [Neon Console](https://console.neon.tech)
2. Create a new project
3. Note your connection string

#### B. Enable Neon Auth

1. In Neon Console, navigate to **Settings** > **Authentication**
2. Enable Neon Auth
3. Configure authentication settings:
   - Enable email/password authentication
   - Note your Auth URL (e.g., `https://auth.neon.tech/your-project`)

#### C. Enable Data API (PostgREST)

1. In Neon Console, navigate to **Settings** > **Data API**
2. Enable the Data API
3. Note your Data API URL (e.g., `https://your-project.neon.tech`)

#### D. Run Database Schema

1. In Neon Console, go to **SQL Editor**
2. Open `Database/schema.sql` from this project
3. Copy and paste the entire SQL script
4. Execute the script to create:
   - Tables: `profiles`, `ratings`, `weekly_scores`, `friendships`
   - Row Level Security (RLS) policies
   - Triggers for automatic user_id setting

#### E. Refresh Data API Schema Cache

After running the schema:
1. Go to **Settings** > **Data API**
2. Click **Refresh Schema** (or restart Data API)
3. This ensures the API recognizes your new tables

### 2. iOS Project Setup

#### A. Configure Xcode Project

1. Open `Iron Core.xcodeproj` in Xcode
2. Select the project in the navigator
3. Under **Signing & Capabilities**:
   - Add your development team
   - Enable **HealthKit** capability
   - Enable **Keychain Sharing** capability

#### B. Update Info.plist

1. Open `Iron Core/Info.plist`
2. Update the following keys with your Neon URLs:

```xml
<key>NEON_DATA_API_URL</key>
<string>https://your-project.neon.tech</string>

<key>NEON_AUTH_URL</key>
<string>https://auth.neon.tech/your-project</string>
```

**IMPORTANT**: Replace with your actual Neon URLs from the console.

#### C. HealthKit Entitlements

The HealthKit permissions are already configured in Info.plist:
- `NSHealthShareUsageDescription`: Explains why app needs health data
- `NSHealthUpdateUsageDescription`: Required for HealthKit access

#### D. Build and Run

1. Select a target device (iOS 17.0+)
2. Build the project (⌘B)
3. Run the app (⌘R)

### 3. Testing the App

#### A. First Launch

1. **Sign Up**:
   - Enter email, password, name, and handle
   - Handle must be unique (e.g., @ironwarrior)
   - App creates profile and initial rating (1000 MMR, 0 LP, UNTRAINED rank)

2. **Connect HealthKit**:
   - Grant permissions for:
     - Workouts
     - Active Energy Burned
     - Apple Exercise Time
     - Sleep Analysis

3. **Home Screen**:
   - View your current rank and LP
   - Calculate this week's score
   - Submit your weekly score

#### B. Using the App

**Calculate Score**:
1. Ensure you have workout and sleep data in Health app
2. Tap "Calculate Score" on Home tab
3. View breakdown: Consistency, Volume, Intensity, Recovery
4. Tap "Submit Week" to save and update your ranking

**Add Friends**:
1. Go to Friends tab
2. Tap "+" button
3. Search by handle (e.g., @ironwarrior)
4. Send friend request
5. Friend accepts request

**View Leaderboard**:
1. Go to Leaderboard tab
2. See weekly rankings of you and your friends
3. Sorted by weekly score (descending)

**Check History**:
1. Go to History tab
2. View past weekly scores
3. See component breakdowns for each week

### 4. Score Calculation Formula

The weekly score is calculated from HealthKit data:

```
Total Score (0-100) = Consistency + Volume + Intensity + Recovery
```

**Consistency (40 points max)**:
- +8 points per day with at least one workout
- Maximum 5 days counted

**Volume (25 points max)**:
- +0.1 points per minute of workout time
- Capped at 250 minutes

**Intensity (25 points max)**:
- +0.025 points per kcal of active energy burned
- Capped at 1000 kcal

**Recovery (10 points max)**:
- +2 points per night with ≥6.5 hours of sleep
- Maximum 5 nights counted

### 5. Ranking System

**MMR/LP System**:
- **MMR** (Hidden): Internal matchmaking rating (starts at 1000)
- **LP** (Visible): League Points shown to users (starts at 0)
- **Expected Score**: `50 + (MMR - 1000) / 20` (clamped 20-85)
- **LP Change**: `(ActualScore - ExpectedScore) * Factor`

**Rank Tiers**:

| Rank | LP Threshold | Division |
|------|--------------|----------|
| UNTRAINED | 0 | III, II, I |
| CONDITIONED | 100 | III, II, I |
| STRONG | 300 | III, II, I |
| ATHLETIC | 600 | III, II, I |
| ELITE | 1000 | III, II, I |
| FORGED | 1500 | III, II, I |
| PRIME | 2100 | III, II, I |
| OVERDRIVE | 2800 | III, II, I |
| APEX | 3600 | III, II, I |
| TITAN | 4500 | None |

**LP Factors** (affects gain/loss rate):
- 0-300 LP: 1.2x
- 300-1000 LP: 1.0x
- 1000-2100 LP: 0.8x
- 2100-3600 LP: 0.7x
- 3600+ LP: 0.6x

### 6. Database Schema & RLS

**Tables**:
- `profiles`: User profiles with handle
- `ratings`: User MMR/LP/rank
- `weekly_scores`: Weekly fitness scores
- `friendships`: Friend relationships

**Row Level Security (RLS)**:

All tables have RLS enabled. Users can only:
- View their own data
- View friend profiles and scores (if friendship accepted)
- Insert/update their own records
- Search public profile handles

**Key RLS Policies**:
```sql
-- Users view own rating
ratings: user_id = auth.user_id()

-- Users view own + friends' scores
weekly_scores: user_id = auth.user_id() OR friend relationship exists

-- Users search all profiles by handle
profiles: SELECT allowed for all (for friend search)
```

### 7. API Integration Details

**Authentication Flow**:
1. User signs up/in via Neon Auth endpoints
2. `GET /api/auth/get-session` returns JWT in `Set-Auth-Jwt` header
3. JWT stored securely in iOS Keychain
4. JWT auto-injected in all Data API requests

**Data API Requests**:

All database operations use the Data API:

```swift
// Example: Fetch user profile
GET {NEON_DATA_API_URL}/rest/v1/profiles?user_id=eq.{userId}
Authorization: Bearer {JWT}
```

**No Direct Postgres Connection**:
- iOS app never connects directly to Postgres
- All operations go through authenticated REST API
- RLS policies enforced at database level

### 8. Security Notes

**JWT Storage**:
- Stored in iOS Keychain (encrypted)
- Never exposed in logs or UI
- Cleared on logout

**RLS Enforcement**:
- All database access controlled by RLS policies
- Even with valid JWT, users can only access authorized data
- Policies defined in `schema.sql`

**No Hardcoded Secrets**:
- Database credentials not in iOS app
- Only public API endpoints in Info.plist
- Backend authentication handled by Neon Auth

### 9. Troubleshooting

**App won't build**:
- Ensure HealthKit capability is enabled
- Check iOS deployment target is 17.0+
- Verify all ViewModels are added to target

**Can't sign in**:
- Verify `NEON_AUTH_URL` is correct in Info.plist
- Check Neon Auth is enabled in console
- Look for error messages in Xcode console

**Can't fetch data**:
- Verify `NEON_DATA_API_URL` is correct
- Ensure Data API is enabled
- Refresh schema cache after SQL changes
- Check RLS policies allow the operation

**HealthKit not working**:
- Must run on physical device or simulator with Health app
- Grant all requested permissions
- Add sample workout/sleep data in Health app

**401 Unauthorized errors**:
- JWT may have expired - try logging out and back in
- Check that JWT is properly stored in Keychain
- Verify RLS policies allow the operation

**Schema changes not reflected**:
- After modifying schema, refresh Data API in Neon Console
- Alternative: Add `Prefer: schema-reload` header to next request

### 10. Development Tips

**Testing Score Calculation**:
1. Use Health app to add sample workouts
2. Add sleep data for recovery points
3. Vary workout types and durations

**Testing Friends/Leaderboard**:
1. Create multiple test accounts
2. Add sample weekly scores for each
3. Send friend requests between accounts

**Debugging RLS**:
1. Use `Database/test_queries.sql` for testing
2. Check policies in Neon Console > SQL Editor
3. Verify `auth.user_id()` returns correct value

**Color Customization**:
- Neon colors defined in `Extensions.swift`
- Modify `Color.neonGreen`, `Color.neonYellow`, etc.
- Dark mode colors in `Color.cardBackground`

## Architecture

**MVVM Pattern**:
- **Models**: Data structures (User, Rating, WeeklyScore, etc.)
- **ViewModels**: Business logic, API calls, state management
- **Views**: SwiftUI UI components, no business logic

**Services Layer**:
- `NeonAuthService`: Handles authentication
- `NeonDataAPIClient`: Generic REST API client
- `HealthKitManager`: HealthKit data fetching
- `ScoreCalculator`: Score computation logic

**State Management**:
- `@EnvironmentObject` for shared ViewModels
- `@Published` properties for reactive updates
- `@MainActor` for UI thread safety

## Roadmap

Potential future enhancements:
- [ ] Push notifications for friend requests
- [ ] Weekly summary emails
- [ ] Workout recommendations
- [ ] Achievement badges
- [ ] Global leaderboards
- [ ] Apple Watch app
- [ ] Social sharing
- [ ] Data export

## License

This project is provided as an MVP example. Customize as needed for your use case.

## Support

For issues or questions:
1. Check Troubleshooting section above
2. Review Neon documentation: https://neon.tech/docs
3. Verify RLS policies in `schema.sql`
4. Check Xcode console for error messages

---

**Built with ❤️ using SwiftUI and Neon Database**
