import Foundation

extension WorkoutViewModel {
    func saveWorkoutExercisesAndSets(sessionId: String, exercises: [ActiveWorkoutExercise]) async {
        for exercise in exercises {
            do {
                // Save workout_exercise
                let exerciseRequest = WorkoutExerciseRequest(
                    sessionId: sessionId,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    notes: nil
                )
                
                let savedExercises: [WorkoutExercise] = try await dataAPI.post(table: "workout_exercises", body: exerciseRequest)
                
                guard let workoutExerciseId = savedExercises.first?.id else {
                    print("❌ [WORKOUT] Failed to get workout_exercise id for \(exercise.exerciseName)")
                    continue
                }
                
                // Save all sets for this exercise (filter out invalid sets)
                let validSets = exercise.completedSets.filter { $0.weight > 0 && $0.reps > 0 }
                
                for set in validSets {
                    let setRequest = WorkoutSetRequest(
                        workoutExerciseId: workoutExerciseId,
                        setNumber: set.setNumber,
                        weight: set.weight,
                        reps: set.reps,
                        setType: set.setType.rawValue,
                        rpe: set.rpe,
                        isPersonalRecord: false,
                        completedAt: set.completedAt
                    )
                    
                    let _: [WorkoutSet] = try await dataAPI.post(table: "workout_sets", body: setRequest)
                }
                
                if validSets.count < exercise.completedSets.count {
                    print("ℹ️ [WORKOUT] Filtered out \(exercise.completedSets.count - validSets.count) invalid sets (weight/reps = 0)")
                }
                
                print("✅ [WORKOUT] Saved \(validSets.count) sets for \(exercise.exerciseName)")
            } catch {
                print("❌ [WORKOUT] Failed to save exercise \(exercise.exerciseName): \(error)")
            }
        }
    }
    
    func getLastWeightsForExercise(exerciseId: String, userId: String) async -> [Double] {
        do {
            // Step 1: Get recent workout sessions for this user
            let sessionQuery: [String: String] = [
                "user_id": "eq.\(userId)",
                "order": "start_time.desc",
                "limit": "10"
            ]
            
            let sessions: [WorkoutSession] = try await dataAPI.get(table: "workout_sessions", query: sessionQuery)
            
            guard !sessions.isEmpty else {
                print("ℹ️ [WORKOUT] No workout history found for user")
                return []
            }
            
            var allWeights: [Double] = []
            
            // Step 2: Collect all weights from all sessions for this exercise
            for session in sessions {
                let exerciseQuery: [String: String] = [
                    "session_id": "eq.\(session.id)",
                    "exercise_id": "eq.\(exerciseId)"
                ]
                
                let workoutExercises: [WorkoutExercise] = try await dataAPI.get(table: "workout_exercises", query: exerciseQuery)
                
                for workoutExercise in workoutExercises {
                    let setsQuery: [String: String] = [
                        "workout_exercise_id": "eq.\(workoutExercise.id)"
                    ]
                    
                    let sets: [WorkoutSet] = try await dataAPI.get(table: "workout_sets", query: setsQuery)
                    allWeights.append(contentsOf: sets.map { $0.weight })
                }
            }
            
            // Step 3: Get unique weights and sort descending (highest to lowest)
            let uniqueWeights = Array(Set(allWeights)).sorted(by: >)
            
            print("✅ [WORKOUT] Loaded \(uniqueWeights.count) unique weights for exercise (sorted desc): \(uniqueWeights)")
            return uniqueWeights
        } catch {
            print("❌ [WORKOUT] Failed to get last weights: \(error)")
            return []
        }
    }
}
