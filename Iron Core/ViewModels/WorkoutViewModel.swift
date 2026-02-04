import Foundation
import Combine
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var activeWorkout: ActiveWorkout?
    @Published var exercises: [Exercise] = []
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let dataAPI = NeonDataAPIClient.shared
    let exerciseDBAPI = ExerciseDBAPIClient.shared
    
    private let routinesCacheKey = "ios_routines_cache"
    
    func deleteRoutine(routineId: String) async {
        do {
            // Delete routine_exercises first (foreign key constraint)
            let _: [RoutineExercise] = try await dataAPI.delete(
                table: "routine_exercises",
                query: ["routine_id": "eq.\(routineId)"]
            )
            
            // Delete routine
            let _: [Routine] = try await dataAPI.delete(
                table: "routines",
                query: ["id": "eq.\(routineId)"]
            )
            
            // Remove from local state
            routines.removeAll { $0.id == routineId }
            
            // Actualizar cache
            saveRoutinesToCache(routines)
            
            print("✅ [ROUTINE] Deleted routine: \(routineId)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [ROUTINE] Failed to delete routine: \(error)")
        }
    }
    
    func loadRoutines() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        // 1. Cargar primero desde cache para mostrar instantáneamente
        loadCachedRoutines()
        
        // 2. Luego actualizar desde BD en background
        isLoading = true
        errorMessage = nil
        
        do {
            var loadedRoutines: [Routine] = try await dataAPI.get(table: "routines", query: ["user_id": "eq.\(userId)"])
            
            for i in 0..<loadedRoutines.count {
                let routineExercises: [RoutineExercise] = try await dataAPI.get(
                    table: "routine_exercises",
                    query: [
                        "routine_id": "eq.\(loadedRoutines[i].id)",
                        "order": "exercise_order.asc"
                    ]
                )
                loadedRoutines[i].exercises = routineExercises
                print("✅ [WORKOUT] Loaded \(routineExercises.count) exercises for routine: \(loadedRoutines[i].name)")
            }
            
            routines = loadedRoutines
            
            // Guardar en cache
            saveRoutinesToCache(loadedRoutines)
            
            print("✅ [WORKOUT] Loaded and cached \(routines.count) routines from DB")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to load routines: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadCachedRoutines() {
        guard let data = UserDefaults.standard.data(forKey: routinesCacheKey) else {
            print("ℹ️ [WORKOUT] No cached routines found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            routines = try decoder.decode([Routine].self, from: data)
            print("✅ [WORKOUT] Loaded \(routines.count) cached routines (instant)")
        } catch {
            print("❌ [WORKOUT] Failed to decode cached routines: \(error)")
        }
    }
    
    private func saveRoutinesToCache(_ routines: [Routine]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(routines)
            UserDefaults.standard.set(data, forKey: routinesCacheKey)
            print("💾 [WORKOUT] Routines saved to cache")
        } catch {
            print("❌ [WORKOUT] Failed to encode routines for cache: \(error)")
        }
    }
    
    func loadExercises() async {
        isLoading = true
        
        do {
            exercises = try await dataAPI.get(table: "exercises", query: [:])
            print("✅ [WORKOUT] Loaded \(exercises.count) exercises")
            
            // Sync exercises without gifUrl
            await syncExercisesWithAPI()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to load exercises: \(error)")
        }
        
        isLoading = false
    }
    
    private func syncExercisesWithAPI() async {
        let exercisesWithoutGif = exercises.filter { $0.gifUrl == nil && !$0.name.isEmpty }
        
        guard !exercisesWithoutGif.isEmpty else {
            print("✅ [WORKOUT] All exercises have GIF URLs")
            return
        }
        
        print("🔄 [WORKOUT] Syncing \(exercisesWithoutGif.count) exercises with ExerciseDB API...")
        
        for exercise in exercisesWithoutGif.prefix(5) { // Limit to 5 at a time to avoid rate limits
            do {
                let matches = try await exerciseDBAPI.searchExercisesByName(name: exercise.name)
                
                if let match = matches.first {
                    // Update exercise in database
                    let updateData: [String: Any] = [
                        "gif_url": match.gifUrl,
                        "exercise_db_id": match.exerciseId,
                        "instructions": match.instructions.joined(separator: "\n")
                    ]
                    
                    guard let url = URL(string: "\(dataAPI.baseURL)/exercises?id=eq.\(exercise.id)") else {
                        continue
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "PATCH"
                    if let jwt = KeychainStore.shared.getJWT() {
                        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                    }
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("return=representation", forHTTPHeaderField: "Prefer")
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: updateData)
                    request.httpBody = jsonData
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse,
                       (200...299).contains(httpResponse.statusCode) {
                        let decoder = JSONDecoder.neonDecoder
                        let updated = try decoder.decode([Exercise].self, from: data)
                        
                        // Update local array
                        if let updatedExercise = updated.first,
                           let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                            exercises[index] = updatedExercise
                            print("✅ [WORKOUT] Synced: \(exercise.name) → \(match.gifUrl)")
                        }
                    }
                }
            } catch {
                print("⚠️ [WORKOUT] Failed to sync \(exercise.name): \(error)")
            }
        }
        
        print("✅ [WORKOUT] Sync completed")
    }
    
    func addExerciseFromAPI(_ apiExercise: ExerciseDBItem) async -> String? {
        guard let userId = KeychainStore.shared.getUserId() else { return nil }
        
        // Check if exercise already exists by exercise_db_id
        do {
            let existing: [Exercise] = try await dataAPI.get(
                table: "exercises",
                query: ["exercise_db_id": "eq.\(apiExercise.exerciseId)"]
            )
            
            if let existingExercise = existing.first {
                print("✅ [WORKOUT] Exercise already exists: \(existingExercise.name)")
                
                // Add to local array if not present
                if !exercises.contains(where: { $0.id == existingExercise.id }) {
                    exercises.append(existingExercise)
                    print("📥 [WORKOUT] Added to local array: \(existingExercise.name)")
                }
                
                return existingExercise.id
            }
        } catch {
            print("⚠️ [WORKOUT] Error checking existing exercise: \(error)")
        }
        
        // Create new exercise from API data
        let category = determineCategory(from: apiExercise.bodyParts)
        let muscleGroup = determineMuscleGroup(from: apiExercise.targetMuscles)
        let equipment = determineEquipment(from: apiExercise.equipments)
        let instructions = apiExercise.instructions.joined(separator: "\n")
        
        let exerciseRequest: [String: Any] = [
            "name": apiExercise.name,
            "category": category.rawValue,
            "muscle_group": muscleGroup.rawValue,
            "equipment": equipment.rawValue,
            "instructions": instructions,
            "gif_url": apiExercise.gifUrl,
            "exercise_db_id": apiExercise.exerciseId,
            "created_by": userId,
            "is_custom": false
        ]
        
        do {
            // Create exercise using raw dictionary since we need flexibility
            guard let url = URL(string: "\(dataAPI.baseURL)/exercises") else {
                throw DataAPIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if let jwt = KeychainStore.shared.getJWT() {
                request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
            
            let jsonData = try JSONSerialization.data(withJSONObject: exerciseRequest)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ [WORKOUT] Response: \(responseString)")
                }
                throw DataAPIError.invalidResponse
            }
            
            // Debug: print response
            if let responseString = String(data: data, encoding: .utf8) {
                print("📝 [WORKOUT] Create response: \(responseString)")
            }
            
            let decoder = JSONDecoder.neonDecoder
            let created = try decoder.decode([Exercise].self, from: data)
            
            if let newExercise = created.first {
                exercises.append(newExercise)
                print("✅ [WORKOUT] Created exercise: \(newExercise.name)")
                return newExercise.id
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to create exercise: \(error)")
        }
        
        return nil
    }
    
    private func determineCategory(from bodyParts: [String]) -> ExerciseCategory {
        let bodyPart = bodyParts.first?.lowercased() ?? ""
        if bodyPart.contains("cardio") {
            return .cardio
        }
        return .strength
    }
    
    private func determineMuscleGroup(from muscles: [String]) -> MuscleGroup {
        let muscle = muscles.first?.lowercased() ?? ""
        
        if muscle.contains("chest") || muscle.contains("pectoralis") {
            return .chest
        } else if muscle.contains("back") || muscle.contains("lats") || muscle.contains("traps") {
            return .back
        } else if muscle.contains("shoulder") || muscle.contains("delts") {
            return .shoulders
        } else if muscle.contains("biceps") {
            return .biceps
        } else if muscle.contains("triceps") {
            return .triceps
        } else if muscle.contains("legs") || muscle.contains("quads") || muscle.contains("hamstrings") || muscle.contains("calves") {
            return .legs
        } else if muscle.contains("glutes") {
            return .glutes
        } else if muscle.contains("abs") || muscle.contains("core") {
            return .core
        }
        
        return .fullBody
    }
    
    private func determineEquipment(from equipments: [String]) -> Equipment {
        let equipment = equipments.first?.lowercased() ?? ""
        
        if equipment.contains("barbell") {
            return .barbell
        } else if equipment.contains("dumbbell") {
            return .dumbbell
        } else if equipment.contains("machine") || equipment.contains("leverage") || equipment.contains("smith") {
            return .machine
        } else if equipment.contains("body") || equipment.contains("bodyweight") {
            return .bodyweight
        } else if equipment.contains("cable") {
            return .cable
        } else if equipment.contains("kettlebell") {
            return .kettlebell
        } else if equipment.contains("band") {
            return .band
        }
        
        return .other
    }
    
    func createRoutine(name: String, description: String?) async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            let request = RoutineRequest(userId: userId, name: name, description: description)
            let newRoutines: [Routine] = try await dataAPI.post(table: "routines", body: request)
            
            if let newRoutine = newRoutines.first {
                routines.append(newRoutine)
                
                // Actualizar cache
                saveRoutinesToCache(routines)
                
                print("✅ [WORKOUT] Routine created: \(name)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to create routine: \(error)")
        }
    }
    
    func reorderExercises(from source: IndexSet, to destination: Int) {
        guard var workout = activeWorkout else { return }
        workout.exercises.move(fromOffsets: source, toOffset: destination)
        activeWorkout = workout
        print("🔄 [WORKOUT] Reordered exercises")
    }
    
    func startWorkout(routine: Routine? = nil) {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        var workoutExercises: [ActiveWorkoutExercise] = []
        
        if let routine = routine {
            workoutExercises = routine.exercises.compactMap { routineExercise in
                // Get the full exercise data
                guard let fullExercise = exercises.first(where: { $0.id == routineExercise.exerciseId }) else {
                    return nil
                }
                
                return ActiveWorkoutExercise(
                    exercise: fullExercise,
                    targetSets: routineExercise.targetSets,
                    targetReps: nil,
                    targetWeight: routineExercise.targetWeight,
                    restTime: routineExercise.restSeconds,
                    completedSets: []
                )
            }
        }
        
        activeWorkout = ActiveWorkout(
            userId: userId,
            routineId: routine?.id,
            routineName: routine?.name,
            routineDescription: routine?.description,
            startTime: Date(),
            exercises: workoutExercises
        )
        
        print("🏋️ [WORKOUT] Started workout: \(routine?.name ?? "Empty Workout") with \(workoutExercises.count) exercises")
    }
    
    func addExercise(to workout: inout ActiveWorkout, exercise: Exercise, targetSets: Int = 3, restSeconds: Int = 90) {
        let workoutExercise = ActiveWorkoutExercise(
            exercise: exercise,
            targetSets: targetSets,
            targetReps: nil,
            targetWeight: nil,
            restTime: restSeconds,
            completedSets: []
        )
        
        workout.exercises.append(workoutExercise)
    }
    
    func completeSet(exerciseIndex: Int, setNumber: Int, weight: Double, reps: Int, setType: SetType = .working, rpe: Int? = nil) {
        guard var workout = activeWorkout else { return }
        
        let set = CompletedSet(
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            setType: setType,
            rpe: rpe,
            completedAt: Date()
        )
        
        workout.exercises[exerciseIndex].completedSets.append(set)
        activeWorkout = workout
        
        print("✅ [WORKOUT] Set \(setNumber) completed: \(weight)kg x \(reps) reps")
    }
    
    func uncompleteSet(exerciseIndex: Int, setNumber: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        
        if let setIndex = workout.exercises[exerciseIndex].completedSets.firstIndex(where: { $0.setNumber == setNumber }) {
            workout.exercises[exerciseIndex].completedSets.remove(at: setIndex)
            activeWorkout = workout
            print("↩️ [WORKOUT] Set \(setNumber) unmarked")
        }
    }
    
    func finishWorkout() async {
        guard var workout = activeWorkout else { return }
        
        workout.endTime = Date()
        
        let duration = Int(workout.endTime!.timeIntervalSince(workout.startTime))
        var totalVolume: Double = 0
        var totalSets = 0
        
        for exercise in workout.exercises {
            for set in exercise.completedSets {
                totalVolume += set.weight * Double(set.reps)
                totalSets += 1
            }
        }
        
        let qualityScore = calculateQualityScore(workout: workout)
        
        // Debug: verificar sets completados
        for (index, exercise) in workout.exercises.enumerated() {
            print("🔍 [WORKOUT] Exercise \(index): \(exercise.exerciseName) - \(exercise.completedSets.count) sets completed")
        }
        
        let sessionRequest = WorkoutSessionRequest(
            userId: workout.userId,
            routineId: workout.routineId,
            routineName: workout.routineName,
            startTime: workout.startTime,
            endTime: workout.endTime,
            totalVolume: totalVolume,
            totalSets: totalSets,
            qualityScore: qualityScore
        )
        
        do {
            let sessions: [WorkoutSession] = try await dataAPI.post(table: "workout_sessions", body: sessionRequest)
            
            if let session = sessions.first {
                workoutHistory.insert(session, at: 0)
                print("✅ [WORKOUT] Workout saved - Quality: \(qualityScore ?? 0)")
                
                // Save exercises and sets
                await saveWorkoutExercisesAndSets(sessionId: session.id, exercises: workout.exercises)
                
                await checkAndAwardLP(session: session, qualityScore: qualityScore ?? 0)
            }
            
            // Save to HealthKit
            do {
                try await HealthKitManager.shared.saveWorkout(
                    routineName: workout.routineName ?? "Workout",
                    startDate: workout.startTime,
                    endDate: workout.endTime!,
                    totalVolume: totalVolume,
                    totalSets: totalSets
                )
            } catch {
                print("⚠️ [HEALTHKIT] Failed to save workout: \(error.localizedDescription)")
                // No lanzar error - el workout ya se guardó en BD
            }
            
            // Update routine exercise order if workout came from a routine
            if let routineId = workout.routineId {
                await updateRoutineExerciseOrder(routineId: routineId, exercises: workout.exercises)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to save workout: \(error)")
        }
        
        activeWorkout = nil
    }
    
    private func updateRoutineExerciseOrder(routineId: String, exercises: [ActiveWorkoutExercise]) async {
        do {
            // Get current routine exercises
            let routineExercises: [RoutineExercise] = try await dataAPI.get(
                table: "routine_exercises",
                query: ["routine_id": "eq.\(routineId)"]
            )
            
            // Update display_order for each exercise based on new order
            for (newIndex, exercise) in exercises.enumerated() {
                if let routineExercise = routineExercises.first(where: { $0.exerciseId == exercise.exerciseId }) {
                    let updateData: [String: Any] = [
                        "display_order": newIndex
                    ]
                    
                    guard let url = URL(string: "\(dataAPI.baseURL)/routine_exercises?id=eq.\(routineExercise.id)") else {
                        continue
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "PATCH"
                    if let jwt = KeychainStore.shared.getJWT() {
                        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
                    }
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: updateData)
                    request.httpBody = jsonData
                    
                    let (_, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse,
                       (200...299).contains(httpResponse.statusCode) {
                        print("✅ [WORKOUT] Updated exercise order: \(exercise.exerciseName) → position \(newIndex)")
                    }
                }
            }
            
            // Reload routines to reflect new order
            await loadRoutines()
        } catch {
            print("⚠️ [WORKOUT] Failed to update routine exercise order: \(error)")
        }
    }
    
    private func calculateQualityScore(workout: ActiveWorkout) -> Double {
        var totalScore: Double = 0
        var exerciseCount = 0
        
        for exercise in workout.exercises {
            guard !exercise.completedSets.isEmpty else { continue }
            
            var exerciseScore: Double = 0
            var qualitySetCount = 0
            
            for set in exercise.completedSets where set.setType == .working {
                if set.reps >= 8 && set.reps <= 10 {
                    exerciseScore += 10.0
                    qualitySetCount += 1
                } else if set.reps >= 6 && set.reps <= 12 {
                    exerciseScore += 7.0
                } else {
                    exerciseScore += 4.0
                }
                
                if let rpe = set.rpe, rpe >= 7 {
                    exerciseScore += 3.0
                }
            }
            
            if qualitySetCount >= 3 {
                exerciseScore *= 1.2
            }
            
            totalScore += exerciseScore
            exerciseCount += 1
        }
        
        return exerciseCount > 0 ? min(100, totalScore / Double(exerciseCount)) : 0
    }
    
    private func checkAndAwardLP(session: WorkoutSession, qualityScore: Double) async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            let ratings: [Rating] = try await dataAPI.get(table: "ratings", query: ["user_id": "eq.\(userId)"])
            
            guard let currentRating = ratings.first else { return }
            
            var lpGain = 0
            
            if qualityScore >= 80 {
                lpGain = 25
            } else if qualityScore >= 70 {
                lpGain = 20
            } else if qualityScore >= 60 {
                lpGain = 15
            } else if qualityScore >= 50 {
                lpGain = 10
            } else {
                lpGain = 5
            }
            
            let prCount = session.exercises?.flatMap { $0.sets ?? [] }.filter { $0.isPersonalRecord }.count ?? 0
            lpGain += prCount * 5
            
            let newLP = currentRating.lp + lpGain
            let newMMR = currentRating.mmr + (lpGain / 2)
            
            print("🎯 [LP] Workout quality: \(qualityScore) - Gained \(lpGain) LP")
            print("🏆 [LP] PRs achieved: \(prCount)")
            
        } catch {
            print("❌ [LP] Failed to award LP: \(error)")
        }
    }
}

// ActiveWorkout, ActiveWorkoutExercise, CompletedSet, and SetType are now in WorkoutModels.swift
