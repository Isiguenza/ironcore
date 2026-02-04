-- IRONCORE Database Schema
-- Run this SQL in your Neon Console to set up the database

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

-- Profiles table: stores user profile information
CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY DEFAULT auth.user_id(),
    handle TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique index on handle for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_handle ON profiles(handle);

-- Ratings table: stores user ranking and MMR data
CREATE TABLE IF NOT EXISTS ratings (
    user_id TEXT PRIMARY KEY,
    mmr INTEGER NOT NULL DEFAULT 1000,
    lp INTEGER NOT NULL DEFAULT 0,
    rank TEXT NOT NULL DEFAULT 'UNTRAINED',
    division INTEGER DEFAULT 3,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_ratings_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE
);

-- Weekly scores table: stores weekly fitness scores
CREATE TABLE IF NOT EXISTS weekly_scores (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL DEFAULT auth.user_id(),
    week_start DATE NOT NULL,
    score INTEGER NOT NULL,
    components JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_weekly_scores_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE
);

-- Create index for faster queries by user and week
CREATE INDEX IF NOT EXISTS idx_weekly_scores_user_week ON weekly_scores(user_id, week_start DESC);

-- Friendships table: manages friend relationships
CREATE TABLE IF NOT EXISTS friendships (
    id BIGSERIAL PRIMARY KEY,
    requester_id TEXT NOT NULL,
    addressee_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_friendships_requester FOREIGN KEY (requester_id) REFERENCES profiles(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_friendships_addressee FOREIGN KEY (addressee_id) REFERENCES profiles(user_id) ON DELETE CASCADE,
    CONSTRAINT check_not_self_friend CHECK (requester_id != addressee_id)
);

-- Create unique constraint to prevent duplicate friend requests
CREATE UNIQUE INDEX IF NOT EXISTS idx_friendships_unique ON friendships(
    LEAST(requester_id, addressee_id),
    GREATEST(requester_id, addressee_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON friendships(addressee_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.user_id() = user_id);

-- Users can view profiles of users they search for (by handle)
-- This allows searching for friends
CREATE POLICY "Users can search profiles by handle"
ON profiles FOR SELECT
USING (true);

-- Users can insert their own profile during registration
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
WITH CHECK (auth.user_id() = user_id OR user_id IS NULL);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.user_id() = user_id);

-- ============================================================================
-- RATINGS POLICIES
-- ============================================================================

-- Users can only view their own rating
CREATE POLICY "Users can view own rating"
ON ratings FOR SELECT
USING (auth.user_id() = user_id);

-- Users can insert their own rating
CREATE POLICY "Users can insert own rating"
ON ratings FOR INSERT
WITH CHECK (auth.user_id() = user_id OR user_id IS NULL);

-- Users can update their own rating
CREATE POLICY "Users can update own rating"
ON ratings FOR UPDATE
USING (auth.user_id() = user_id);

-- ============================================================================
-- WEEKLY_SCORES POLICIES
-- ============================================================================

-- Users can view their own scores
CREATE POLICY "Users can view own scores"
ON weekly_scores FOR SELECT
USING (auth.user_id() = user_id);

-- Users can view scores of their friends
CREATE POLICY "Users can view friends scores"
ON weekly_scores FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM friendships
        WHERE status = 'accepted'
        AND (
            (requester_id = auth.user_id() AND addressee_id = weekly_scores.user_id)
            OR
            (addressee_id = auth.user_id() AND requester_id = weekly_scores.user_id)
        )
    )
);

-- Users can insert their own scores
CREATE POLICY "Users can insert own scores"
ON weekly_scores FOR INSERT
WITH CHECK (auth.user_id() = user_id OR user_id IS NULL);

-- Users can update their own scores (optional, if you want to allow updates)
CREATE POLICY "Users can update own scores"
ON weekly_scores FOR UPDATE
USING (auth.user_id() = user_id);

-- ============================================================================
-- FRIENDSHIPS POLICIES
-- ============================================================================

-- Users can view friendships where they are involved
CREATE POLICY "Users can view own friendships"
ON friendships FOR SELECT
USING (auth.user_id() = requester_id OR auth.user_id() = addressee_id);

-- Users can send friend requests (create new friendships)
CREATE POLICY "Users can send friend requests"
ON friendships FOR INSERT
WITH CHECK (auth.user_id() = requester_id OR requester_id IS NULL);

-- Only the addressee can update the status (accept/reject)
CREATE POLICY "Addressee can update friendship status"
ON friendships FOR UPDATE
USING (auth.user_id() = addressee_id);

-- Users can delete friendships where they are involved
CREATE POLICY "Users can delete own friendships"
ON friendships FOR DELETE
USING (auth.user_id() = requester_id OR auth.user_id() = addressee_id);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to automatically set user_id on insert if NULL
CREATE OR REPLACE FUNCTION set_user_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id := auth.user_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for profiles
DROP TRIGGER IF EXISTS set_profiles_user_id ON profiles;
CREATE TRIGGER set_profiles_user_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id();

-- Trigger for ratings
DROP TRIGGER IF EXISTS set_ratings_user_id ON ratings;
CREATE TRIGGER set_ratings_user_id
    BEFORE INSERT ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id();

-- Trigger for weekly_scores
DROP TRIGGER IF EXISTS set_weekly_scores_user_id ON weekly_scores;
CREATE TRIGGER set_weekly_scores_user_id
    BEFORE INSERT ON weekly_scores
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id();

-- Trigger for friendships (requester_id)
CREATE OR REPLACE FUNCTION set_requester_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.requester_id IS NULL THEN
        NEW.requester_id := auth.user_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_friendships_requester_id ON friendships;
CREATE TRIGGER set_friendships_requester_id
    BEFORE INSERT ON friendships
    FOR EACH ROW
    EXECUTE FUNCTION set_requester_id();

-- ============================================================================
-- NOTES
-- ============================================================================

-- After running this schema:
-- 1. Make sure Neon Auth is enabled in your Neon Console
-- 2. Enable Data API (PostgREST) in your Neon Console
-- 3. After schema changes, refresh the Data API schema cache by:
--    - Going to Neon Console > Data API settings
--    - Click "Refresh Schema" or restart the Data API
-- 4. Test your RLS policies by making authenticated requests from your iOS app

-- To refresh schema cache via API (alternative method):
-- POST to your Neon Data API endpoint with header:
-- Prefer: schema-reload

COMMENT ON TABLE profiles IS 'User profiles with handle and display name';
COMMENT ON TABLE ratings IS 'User ranking data with MMR and LP system';
COMMENT ON TABLE weekly_scores IS 'Weekly fitness scores calculated from HealthKit data';
COMMENT ON TABLE friendships IS 'Friend relationships between users';
