-- ============================================================================
-- TEST: Manual insert to verify tables work
-- ============================================================================
-- Run this in Neon Console SQL Editor to test if tables exist and work

-- 1. Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'ratings', 'weekly_scores', 'friendships');

-- 2. Try to insert a test profile directly (replace with your actual user_id from JWT)
INSERT INTO profiles (user_id, handle, display_name)
VALUES ('277a6497-3ca5-460b-a962-d500b2dafc02', 'testhandle123', 'Test User')
ON CONFLICT (user_id) DO UPDATE SET display_name = 'Test User Updated';

-- 3. Try to insert a test rating
INSERT INTO ratings (user_id, mmr, lp, rank, division)
VALUES ('277a6497-3ca5-460b-a962-d500b2dafc02', 1000, 0, 'UNTRAINED', 3)
ON CONFLICT (user_id) DO UPDATE SET mmr = 1000;

-- 4. Verify inserts worked
SELECT * FROM profiles WHERE user_id = '277a6497-3ca5-460b-a962-d500b2dafc02';
SELECT * FROM ratings WHERE user_id = '277a6497-3ca5-460b-a962-d500b2dafc02';

-- 5. Check if RLS is really disabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'ratings', 'weekly_scores', 'friendships');
