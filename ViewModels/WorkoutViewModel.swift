import Foundation
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var activeWorkout: ActiveWorkout?
    @Published var exercises: [Exercise] = []
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let dataAPI = NeonDataAPIClient.shared
    
    func loadRoutines() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
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
            print("✅ [WORKOUT] Loaded \(routines.count) routines")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to load routines: \(error)")
        }
        
        isLoading = false
    }
    
    func loadExercises() async {
        isLoading = true
        
        do {
            exercises = try await dataAPI.get(table: "exercises", query: [:])
            print("✅ [WORKOUT] Loaded \(exercises.count) exercises")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to load exercises: \(error)")
        }
        
        isLoading = false
    }
    
    func createRoutine(name: String, description: String?) async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            let request = RoutineRequest(userId: userId, name: name, description: description)
            let newRoutines: [Routine] = try await dataAPI.post(table: "routines", body: request)
            
            if let newRoutine = newRoutines.first {
                routines.append(newRoutine)
                print("✅ [WORKOUT] Routine created: \(name)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to create routine: \(error)")
        }
    }
    
    func startWorkout(routine: Routine? = nil) {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        var workoutExercises: [ActiveWorkoutExercise] = []
        
        if let routine = routine {
            workoutExercises = routine.exercises.map { exercise in
                ActiveWorkoutExercise(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    targetSets: exercise.targetSets,
                    restSeconds: exercise.restSeconds,
                    completedSets: []
                )
            }
        }
        
        activeWorkout = ActiveWorkout(
            userId: userId,
            routineId: routine?.id,
            routineName: routine?.name,
            startTime: Date(),
            exercises: workoutExercises
        )
        
        print("🏋️ [WORKOUT] Started workout: \(routine?.name ?? "Empty Workout") with \(workoutExercises.count) exercises")
    }
    
    func addExercise(to workout: inout ActiveWorkout, exercise: Exercise, targetSets: Int = 3, restSeconds: Int = 90) {
        let workoutExercise = ActiveWorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            targetSets: targetSets,
            restSeconds: restSeconds,
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
                
                await checkAndAwardLP(session: session, qualityScore: qualityScore ?? 0)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [WORKOUT] Failed to save workout: \(error)")
        }
        
        activeWorkout = nil
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
            
            let prCount = session.exercises.flatMap { $0.sets }.filter { $0.isPersonalRecord }.count
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

struct ActiveWorkout {
    let userId: String
    let routineId: String?
    let routineName: String?
    let startTime: Date
    var endTime: Date?
    var exercises: [ActiveWorkoutExercise]
}

struct ActiveWorkoutExercise: Identifiable {
    let id = UUID()
    let exerciseId: String
    let exerciseName: String
    let targetSets: Int
    var restSeconds: Int
    var completedSets: [CompletedSet]
}

struct CompletedSet: Identifiable {
    let id = UUID()
    let setNumber: Int
    let weight: Double
    let reps: Int
    let setType: SetType
    let rpe: Int?
    let completedAt: Date
}
