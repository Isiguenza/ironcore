-- ============================================================================
-- SIMPLIFIED SCHEMA - Without Neon Auth dependency
-- ============================================================================
-- This schema removes dependency on auth.user_id() and RLS
-- Use this if Neon Auth JWT doesn't work with Data API

-- Drop existing tables if you need to start fresh
-- DROP TABLE IF EXISTS friendships CASCADE;
-- DROP TABLE IF EXISTS weekly_scores CASCADE;
-- DROP TABLE IF EXISTS ratings CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;

-- Profiles table: stores user profile information
CREATE TABLE IF NOT EXISTS profiles (
    user_id TEXT PRIMARY KEY,
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
    user_id TEXT NOT NULL,
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
    CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id)
);

-- NO RLS POLICIES - Tables are open
-- Authentication and authorization handled on client side

COMMENT ON TABLE profiles IS 'User profiles with handle and display name';
COMMENT ON TABLE ratings IS 'User ranking data with MMR and LP system';
COMMENT ON TABLE weekly_scores IS 'Weekly fitness scores calculated from HealthKit data';
COMMENT ON TABLE friendships IS 'Friend relationships between users';
