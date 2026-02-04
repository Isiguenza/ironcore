# IRONCORE - Quick Setup Guide

This is a condensed setup guide. For full documentation, see [README.md](README.md).

## 🚀 Quick Start (5 Steps)

### Step 1: Neon Database Setup

1. Create account at [neon.tech](https://neon.tech)
2. Create new project
3. Enable **Neon Auth** in Settings > Authentication
4. Enable **Data API** in Settings > Data API
5. Copy your URLs:
   - Data API URL: `https://your-project.neon.tech`
   - Auth URL: `https://auth.neon.tech/your-project`

### Step 2: Run Database Schema

1. Open Neon Console > SQL Editor
2. Copy entire contents of `Database/schema.sql`
3. Paste and execute
4. Go to Settings > Data API > Click "Refresh Schema"

### Step 3: Configure iOS App

1. Open `Iron Core.xcodeproj` in Xcode
2. Edit `Iron Core/Info.plist`:

```xml
<key>NEON_DATA_API_URL</key>
<string>YOUR_DATA_API_URL_HERE</string>

<key>NEON_AUTH_URL</key>
<string>YOUR_AUTH_URL_HERE</string>
```

3. In Xcode project settings:
   - Add your Team under Signing & Capabilities
   - Verify HealthKit capability is enabled

### Step 4: Build & Run

1. Select target device (iOS 17.0+)
2. Press ⌘R to run
3. App should launch successfully

### Step 5: Test the App

1. **Sign Up**: Create account with email/password/handle
2. **Connect HealthKit**: Grant all requested permissions
3. **Add Health Data**: 
   - Open Health app
   - Add sample workout (any type)
   - Add sleep data (optional)
4. **Calculate Score**: 
   - Return to IRONCORE
   - Tap "Calculate Score" on Home tab
   - Tap "Submit Week"
5. **Add Friends**: 
   - Friends tab > "+" button
   - Search by handle
   - Send request

## 📋 Checklist

Before running the app, ensure:

- [ ] Neon project created
- [ ] Neon Auth enabled
- [ ] Data API enabled
- [ ] `schema.sql` executed in Neon Console
- [ ] Schema cache refreshed
- [ ] `NEON_DATA_API_URL` set in Info.plist
- [ ] `NEON_AUTH_URL` set in Info.plist
- [ ] HealthKit capability enabled in Xcode
- [ ] Development team selected
- [ ] iOS 17.0+ device selected

## 🔧 Common Issues

### "Invalid URL" errors
- Check Info.plist URLs are correct
- Ensure URLs don't have trailing slashes
- Format: `https://your-project.neon.tech` (no /rest/v1)

### "Unauthorized" errors
- Verify Neon Auth is enabled
- Check JWT is stored (logout and login again)
- Ensure RLS policies are created (`schema.sql`)

### HealthKit not working
- Must use device with Health app
- Grant all 4 permissions
- Add sample data in Health app first

### Can't find friends
- Both users must have registered
- Search exact handle (case-sensitive)
- Handle must be unique in database

### Score shows 0
- Need workout data in Health app
- Must be from current week (Monday-Sunday)
- Check HealthKit permissions granted

## 📱 App Flow

```
Launch → Onboarding (if not logged in)
       ↓
    Sign Up/In
       ↓
    Connect HealthKit
       ↓
    Home (Main Tab)
       ├── Calculate Score
       ├── Submit Week
       ├── View Rank/LP
       └── See Breakdown
       
    Friends Tab
       ├── Search Users
       ├── Send Requests
       └── Accept Requests
       
    Leaderboard Tab
       └── See Friends' Scores
       
    History Tab
       └── View Past Weeks
       
    Settings Tab
       ├── View Profile
       └── Sign Out
```

## 🎯 Score Breakdown

| Component | Max Points | How to Earn |
|-----------|-----------|-------------|
| Consistency | 40 | Workout 5+ days (8 pts/day) |
| Volume | 25 | 250+ minutes total (0.1 pts/min) |
| Intensity | 25 | 1000+ kcal burned (0.025 pts/kcal) |
| Recovery | 10 | 5+ nights 6.5h+ sleep (2 pts/night) |

**Total**: 100 points maximum

## 🏆 Ranks

- **UNTRAINED**: 0 LP
- **CONDITIONED**: 100 LP
- **STRONG**: 300 LP
- **ATHLETIC**: 600 LP
- **ELITE**: 1000 LP
- **FORGED**: 1500 LP
- **PRIME**: 2100 LP
- **OVERDRIVE**: 2800 LP
- **APEX**: 3600 LP
- **TITAN**: 4500 LP

Each rank has 3 divisions (III, II, I) except TITAN.

## 🔒 Security Features

- ✅ JWT tokens stored in Keychain (encrypted)
- ✅ Row Level Security (RLS) on all tables
- ✅ No direct database credentials in app
- ✅ All API calls authenticated
- ✅ Users can only access their own data + friends' data

## 📞 Need Help?

1. Read full [README.md](README.md)
2. Check `Database/test_queries.sql` for SQL examples
3. Review RLS policies in `Database/schema.sql`
4. Check Xcode console for error messages
5. Verify Neon Console shows Auth + Data API as enabled

---

**You're ready to go! 🎉**

Start by signing up, connecting HealthKit, and calculating your first score.
