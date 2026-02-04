-- ============================================================================
-- WORKOUT TRACKING SCHEMA - Sistema de ejercicios tipo Hevy
-- ============================================================================

-- Exercises: Biblioteca de ejercicios disponibles
CREATE TABLE IF NOT EXISTS exercises (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('strength', 'cardio', 'flexibility', 'custom')),
    muscle_group TEXT NOT NULL,
    equipment TEXT NOT NULL,
    instructions TEXT,
    video_url TEXT,
    image_url TEXT,
    gif_url TEXT,
    exercise_db_id TEXT,
    created_by TEXT,
    is_custom BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX IF NOT EXISTS idx_exercises_category ON exercises(category);

-- Routines: Plantillas de entrenamiento reutilizables
CREATE TABLE IF NOT EXISTS routines (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_routines_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_routines_user ON routines(user_id);

-- Routine Exercises: Ejercicios dentro de una rutina
CREATE TABLE IF NOT EXISTS routine_exercises (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    routine_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    exercise_name TEXT NOT NULL,
    exercise_order INTEGER NOT NULL,
    target_sets INTEGER NOT NULL DEFAULT 3,
    target_reps TEXT NOT NULL DEFAULT '8-10',
    target_weight DECIMAL(10,2),
    rest_seconds INTEGER DEFAULT 90,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_routine_exercises_routine FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE,
    CONSTRAINT fk_routine_exercises_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine ON routine_exercises(routine_id);

-- Workout Sessions: Sesiones de entrenamiento completadas
CREATE TABLE IF NOT EXISTS workout_sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    routine_id TEXT,
    routine_name TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER,
    total_volume DECIMAL(10,2) DEFAULT 0,
    total_sets INTEGER DEFAULT 0,
    quality_score DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_workout_sessions_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user ON workout_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_start_time ON workout_sessions(start_time DESC);

-- Workout Exercises: Ejercicios realizados en una sesión
CREATE TABLE IF NOT EXISTS workout_exercises (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    session_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    exercise_name TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_workout_exercises_session FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_workout_exercises_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id)
);

CREATE INDEX IF NOT EXISTS idx_workout_exercises_session ON workout_exercises(session_id);

-- Workout Sets: Sets individuales completados
CREATE TABLE IF NOT EXISTS workout_sets (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    workout_exercise_id TEXT NOT NULL,
    set_number INTEGER NOT NULL,
    weight DECIMAL(10,2) NOT NULL,
    reps INTEGER NOT NULL,
    set_type TEXT NOT NULL DEFAULT 'working' CHECK (set_type IN ('warmup', 'working', 'dropset', 'failure')),
    rpe INTEGER CHECK (rpe >= 1 AND rpe <= 10),
    is_personal_record BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_workout_sets_exercise FOREIGN KEY (workout_exercise_id) REFERENCES workout_exercises(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise ON workout_sets(workout_exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_pr ON workout_sets(is_personal_record) WHERE is_personal_record = true;

-- Exercise History: Historial de performance por ejercicio
CREATE TABLE IF NOT EXISTS exercise_history (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    date DATE NOT NULL,
    max_weight DECIMAL(10,2),
    max_reps INTEGER,
    total_volume DECIMAL(10,2),
    total_sets INTEGER,
    best_set_volume DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_exercise_history_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_exercise_history_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id)
);

CREATE INDEX IF NOT EXISTS idx_exercise_history_user_exercise ON exercise_history(user_id, exercise_id, date DESC);

-- Personal Records: Registros personales
CREATE TABLE IF NOT EXISTS personal_records (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    weight DECIMAL(10,2) NOT NULL,
    reps INTEGER NOT NULL,
    volume DECIMAL(10,2) NOT NULL,
    achieved_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_personal_records_user FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_personal_records_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id)
);

CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise ON personal_records(user_id, exercise_id);

COMMENT ON TABLE exercises IS 'Biblioteca de ejercicios disponibles en la app';
COMMENT ON TABLE routines IS 'Plantillas de entrenamiento reutilizables creadas por usuarios';
COMMENT ON TABLE routine_exercises IS 'Ejercicios que forman parte de una rutina';
COMMENT ON TABLE workout_sessions IS 'Sesiones de entrenamiento completadas';
COMMENT ON TABLE workout_exercises IS 'Ejercicios realizados en cada sesión';
COMMENT ON TABLE workout_sets IS 'Sets individuales completados durante entrenamientos';
COMMENT ON TABLE exercise_history IS 'Historial agregado de performance por ejercicio';
COMMENT ON TABLE personal_records IS 'Récords personales del usuario';
