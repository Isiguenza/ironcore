-- ============================================================================
-- TEMPORARY: DISABLE RLS FOR DEBUGGING
-- ============================================================================
-- Run this SQL in Neon Console to temporarily disable RLS and test if data flows correctly
-- This will help identify if RLS policies are causing the 400 errors

-- Disable RLS on all tables temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE ratings DISABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE friendships DISABLE ROW LEVEL SECURITY;

-- After testing, you can re-enable with:
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE weekly_scores ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
