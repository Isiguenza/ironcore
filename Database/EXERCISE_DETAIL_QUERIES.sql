-- ============================================================================
-- EXERCISE DETAIL QUERIES - For ExerciseDetailView data fetching
-- ============================================================================
-- These queries are needed for the Exercise Detail screen functionality
-- Reference for backend API endpoints

-- ============================================================================
-- 1. GET EXERCISE HISTORY (for History tab)
-- ============================================================================
-- Returns workout history for a specific exercise
-- Shows workout name, date, and all sets performed

SELECT 
    ws.id as session_id,
    ws.routine_name as workout_name,
    ws.start_time as date,
    wsets.set_number,
    wsets.weight,
    wsets.reps,
    wsets.set_type
FROM workout_sessions ws
JOIN workout_exercises we ON ws.id = we.session_id
JOIN workout_sets wsets ON we.id = wsets.workout_exercise_id
WHERE ws.user_id = $1 
  AND we.exercise_id = $2
  AND ws.end_time IS NOT NULL
ORDER BY ws.start_time DESC, wsets.set_number ASC
LIMIT 100;

-- ============================================================================
-- 2. GET PERSONAL RECORDS (for Overview tab - Records section)
-- ============================================================================
-- Returns the best records for an exercise

-- Max Weight PR
SELECT 
    pr.weight,
    pr.reps,
    pr.volume,
    pr.achieved_at
FROM personal_records pr
WHERE pr.user_id = $1 
  AND pr.exercise_id = $2
ORDER BY pr.weight DESC
LIMIT 1;

-- Best 1RM (calculated or stored)
SELECT 
    pr.weight,
    pr.reps,
    pr.volume,
    pr.achieved_at
FROM personal_records pr
WHERE pr.user_id = $1 
  AND pr.exercise_id = $2
ORDER BY pr.volume DESC
LIMIT 1;

-- ============================================================================
-- 3. GET EXERCISE STATS (for Overview tab - Chart)
-- ============================================================================
-- Returns aggregated stats per day for charting
-- Shows progression over time

SELECT 
    eh.date,
    eh.max_weight,
    eh.total_volume,
    eh.total_sets,
    eh.max_reps
FROM exercise_history eh
WHERE eh.user_id = $1 
  AND eh.exercise_id = $2
ORDER BY eh.date DESC
LIMIT 365;

-- ============================================================================
-- 4. GET LAST PERFORMED WEIGHTS (for "LAST" column in active workout)
-- ============================================================================
-- Returns the weight used in the most recent workout for each set number
-- This populates the "LAST" column when doing a new workout

SELECT 
    wsets.set_number,
    wsets.weight,
    wsets.reps,
    MAX(ws.start_time) as last_performed
FROM workout_sessions ws
JOIN workout_exercises we ON ws.id = we.session_id
JOIN workout_sets wsets ON we.id = wsets.workout_exercise_id
WHERE ws.user_id = $1 
  AND we.exercise_id = $2
  AND ws.end_time IS NOT NULL
GROUP BY wsets.set_number, wsets.weight, wsets.reps
ORDER BY last_performed DESC, wsets.set_number ASC;

-- Alternative: Get most recent workout's sets
WITH most_recent_session AS (
    SELECT ws.id
    FROM workout_sessions ws
    JOIN workout_exercises we ON ws.id = we.session_id
    WHERE ws.user_id = $1 
      AND we.exercise_id = $2
      AND ws.end_time IS NOT NULL
    ORDER BY ws.start_time DESC
    LIMIT 1
)
SELECT 
    wsets.set_number,
    wsets.weight,
    wsets.reps
FROM workout_sets wsets
JOIN workout_exercises we ON wsets.workout_exercise_id = we.id
WHERE we.session_id = (SELECT id FROM most_recent_session)
ORDER BY wsets.set_number ASC;

-- ============================================================================
-- 5. GET EXERCISE DETAILS (for Overview tab - Exercise info)
-- ============================================================================
-- Returns basic exercise information

SELECT 
    e.id,
    e.name,
    e.muscle_group,
    e.equipment,
    e.category,
    e.instructions
FROM exercises e
WHERE e.id = $1;

-- ============================================================================
-- NOTES FOR IMPLEMENTATION:
-- ============================================================================
-- These queries should be implemented as API endpoints in your backend:
--
-- GET /api/exercises/:exerciseId/history?userId={userId}
--   → Returns exercise history (Query #1)
--
-- GET /api/exercises/:exerciseId/records?userId={userId}
--   → Returns personal records (Query #2)
--
-- GET /api/exercises/:exerciseId/stats?userId={userId}&period={year|month|all}
--   → Returns stats for charting (Query #3)
--
-- GET /api/exercises/:exerciseId/last-performed?userId={userId}
--   → Returns last workout's weights (Query #4)
--
-- GET /api/exercises/:exerciseId
--   → Returns exercise details (Query #5)
--
-- ============================================================================
-- SCHEMA VERIFICATION:
-- ============================================================================
-- Verify all required tables exist:

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'exercises',
    'workout_sessions',
    'workout_exercises', 
    'workout_sets',
    'exercise_history',
    'personal_records'
);

-- Expected result: 6 rows
-- If missing any, run WORKOUT_SCHEMA.sql first
