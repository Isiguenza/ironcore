-- Migration: Add ExerciseDB API fields to exercises table
-- Run this on your Neon database to add the missing columns

-- Add exercise_db_id column (to store ExerciseDB API ID)
ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS exercise_db_id TEXT;

-- Add gif_url column (to store exercise GIF URL)
ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS gif_url TEXT;

-- Add image_url column (to store exercise image URL)
ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Create index on exercise_db_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_exercises_exercise_db_id 
ON exercises(exercise_db_id);

-- Verify columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'exercises' 
  AND column_name IN ('exercise_db_id', 'gif_url', 'image_url');
