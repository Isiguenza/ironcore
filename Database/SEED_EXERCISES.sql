-- ============================================================================
-- SEED DATA - Ejercicios básicos pre-cargados
-- ============================================================================

INSERT INTO exercises (id, name, category, muscle_group, equipment, instructions, is_custom) VALUES
-- CHEST
('ex_bench_press', 'Bench Press', 'strength', 'chest', 'barbell', 'Lie on bench, lower bar to chest, press up', false),
('ex_incline_bench', 'Incline Bench Press', 'strength', 'chest', 'barbell', 'Set bench at 30-45°, press barbell', false),
('ex_dumbbell_press', 'Dumbbell Bench Press', 'strength', 'chest', 'dumbbell', 'Lie on bench, press dumbbells up', false),
('ex_push_ups', 'Push Ups', 'strength', 'chest', 'bodyweight', 'Lower chest to ground, push back up', false),
('ex_chest_fly', 'Chest Fly', 'strength', 'chest', 'dumbbell', 'Arms wide, bring dumbbells together', false),

-- BACK
('ex_deadlift', 'Deadlift', 'strength', 'back', 'barbell', 'Lift bar from ground to standing', false),
('ex_pull_ups', 'Pull Ups', 'strength', 'back', 'bodyweight', 'Hang from bar, pull chin above bar', false),
('ex_bent_row', 'Bent Over Row', 'strength', 'back', 'barbell', 'Bend forward, row bar to chest', false),
('ex_lat_pulldown', 'Lat Pulldown', 'strength', 'back', 'machine', 'Pull bar down to chest', false),
('ex_t_bar_row', 'T-Bar Row', 'strength', 'back', 'barbell', 'Row T-bar to chest', false),

-- SHOULDERS
('ex_overhead_press', 'Overhead Press', 'strength', 'shoulders', 'barbell', 'Press bar overhead from shoulders', false),
('ex_dumbbell_shoulder', 'Dumbbell Shoulder Press', 'strength', 'shoulders', 'dumbbell', 'Press dumbbells overhead', false),
('ex_lateral_raise', 'Lateral Raise', 'strength', 'shoulders', 'dumbbell', 'Raise arms to sides', false),
('ex_front_raise', 'Front Raise', 'strength', 'shoulders', 'dumbbell', 'Raise arms to front', false),
('ex_face_pulls', 'Face Pulls', 'strength', 'shoulders', 'cable', 'Pull rope to face', false),

-- LEGS
('ex_squat', 'Squat', 'strength', 'legs', 'barbell', 'Squat down, push back up', false),
('ex_leg_press', 'Leg Press', 'strength', 'legs', 'machine', 'Press platform with feet', false),
('ex_lunges', 'Lunges', 'strength', 'legs', 'dumbbell', 'Step forward, lower body', false),
('ex_leg_curl', 'Leg Curl', 'strength', 'legs', 'machine', 'Curl legs up from lying position', false),
('ex_leg_extension', 'Leg Extension', 'strength', 'legs', 'machine', 'Extend legs from seated', false),

-- ARMS
('ex_barbell_curl', 'Barbell Curl', 'strength', 'biceps', 'barbell', 'Curl bar to shoulders', false),
('ex_dumbbell_curl', 'Dumbbell Curl', 'strength', 'biceps', 'dumbbell', 'Curl dumbbells to shoulders', false),
('ex_hammer_curl', 'Hammer Curl', 'strength', 'biceps', 'dumbbell', 'Curl with neutral grip', false),
('ex_tricep_pushdown', 'Tricep Pushdown', 'strength', 'triceps', 'cable', 'Push cable down', false),
('ex_dips', 'Dips', 'strength', 'triceps', 'bodyweight', 'Lower body between bars', false),

-- CORE
('ex_plank', 'Plank', 'strength', 'core', 'bodyweight', 'Hold body straight on forearms', false),
('ex_crunches', 'Crunches', 'strength', 'core', 'bodyweight', 'Lift shoulders off ground', false),
('ex_russian_twist', 'Russian Twist', 'strength', 'core', 'bodyweight', 'Twist torso side to side', false),
('ex_leg_raises', 'Leg Raises', 'strength', 'core', 'bodyweight', 'Raise legs from lying', false)

ON CONFLICT (id) DO NOTHING;
