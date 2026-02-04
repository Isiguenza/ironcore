-- IRONCORE Test Queries
-- Use these queries to verify your setup and test RLS policies

-- ============================================================================
-- BASIC DATA QUERIES (run these after user registration)
-- ============================================================================

-- View all profiles (will only show accessible profiles based on RLS)
SELECT * FROM profiles;

-- View your rating
SELECT * FROM ratings WHERE user_id = auth.user_id();

-- View your weekly scores
SELECT * FROM weekly_scores WHERE user_id = auth.user_id();

-- View your friendships
SELECT * FROM friendships WHERE requester_id = auth.user_id() OR addressee_id = auth.user_id();

-- ============================================================================
-- LEADERBOARD QUERY EXAMPLE
-- ============================================================================

-- Get this week's leaderboard for you and your friends
WITH friend_ids AS (
    SELECT 
        CASE 
            WHEN requester_id = auth.user_id() THEN addressee_id
            ELSE requester_id
        END as friend_id
    FROM friendships
    WHERE status = 'accepted'
    AND (requester_id = auth.user_id() OR addressee_id = auth.user_id())
),
all_user_ids AS (
    SELECT friend_id as user_id FROM friend_ids
    UNION
    SELECT auth.user_id() as user_id
)
SELECT 
    p.display_name,
    p.handle,
    r.rank,
    r.division,
    r.lp,
    ws.score,
    ws.components
FROM all_user_ids u
JOIN profiles p ON p.user_id = u.user_id
LEFT JOIN ratings r ON r.user_id = u.user_id
LEFT JOIN weekly_scores ws ON ws.user_id = u.user_id 
    AND ws.week_start = DATE_TRUNC('week', CURRENT_DATE)
ORDER BY ws.score DESC NULLS LAST;

-- ============================================================================
-- TEST RLS POLICIES
-- ============================================================================

-- These should fail (return 0 rows or error) due to RLS:

-- Try to view another user's rating (should fail)
SELECT * FROM ratings WHERE user_id != auth.user_id();

-- Try to insert a score for another user (should fail)
INSERT INTO weekly_scores (user_id, week_start, score, components)
VALUES ('other-user-id', CURRENT_DATE, 85, '{"consistency": 32, "volume": 20, "intensity": 23, "recovery": 10}'::jsonb);

-- ============================================================================
-- ADMIN QUERIES (bypass RLS - only for debugging)
-- ============================================================================

-- Count total users
SELECT COUNT(*) as total_users FROM profiles;

-- Count weekly scores submitted
SELECT COUNT(*) as total_scores FROM weekly_scores;

-- Count friendships by status
SELECT status, COUNT(*) as count
FROM friendships
GROUP BY status;

-- Average score this week
SELECT 
    AVG(score) as avg_score,
    MAX(score) as max_score,
    MIN(score) as min_score
FROM weekly_scores
WHERE week_start = DATE_TRUNC('week', CURRENT_DATE);

-- ============================================================================
-- CLEANUP QUERIES (use with caution)
-- ============================================================================

-- Delete all data from a specific user (cascade will handle related records)
-- DELETE FROM profiles WHERE user_id = 'user-id-here';

-- Reset all ratings to default
-- UPDATE ratings SET mmr = 1000, lp = 0, rank = 'UNTRAINED', division = 3;

-- Delete old weekly scores (older than 3 months)
-- DELETE FROM weekly_scores WHERE created_at < NOW() - INTERVAL '3 months';
