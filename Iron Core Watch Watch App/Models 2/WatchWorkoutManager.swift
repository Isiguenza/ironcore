import Foundation
import Combine
import HealthKit
import WatchConnectivity

@MainActor
class WatchWorkoutManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutManager()
    
    @Published var routines: [Routine] = []
    @Published var activeWorkout: ActiveWorkout?
    @Published var heartRate: Int = 0
    @Published var calories: Int = 0
    @Published var isResting = false
    @Published var restTimeRemaining = 0
    @Published var additionalSetsByExercise: [Int: Int] = [:] // exerciseIndex: additionalSetsCount
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var startDate: Date?
    private var restTimer: Timer?
    
    private let routinesCacheKey = "watch_routines_cache"
    
    private override init() {
        super.init()
        requestHealthKitAuthorization()
        loadCachedRoutines()
    }
    
    // MARK: - HealthKit Authorization
    
    private func requestHealthKitAuthorization() {
        let typesToShare: Set = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("❌ [WATCH] HealthKit authorization failed: \(error)")
            } else {
                print("✅ [WATCH] HealthKit authorized")
            }
        }
    }
    
    // MARK: - Routine Management
    
    func syncRoutines() {
        WatchConnectivityManager.shared.requestRoutines()
    }
    
    func loadRoutines(from data: Data) {
        do {
            let decoder = JSONDecoder()
            let newRoutines = try decoder.decode([Routine].self, from: data)
            
            // Solo actualizar si hay rutinas válidas
            // Esto previene borrar el cache si el iPhone no tiene sesión
            if !newRoutines.isEmpty {
                routines = newRoutines
                
                // Guardar en UserDefaults para persistencia
                saveRoutinesToCache(data)
                
                print("✅ [WATCH] Loaded and cached \(routines.count) routines")
            } else {
                print("⚠️ [WATCH] Received empty routines array, keeping cached routines")
            }
        } catch {
            print("❌ [WATCH] Failed to decode routines: \(error)")
        }
    }
    
    private func loadCachedRoutines() {
        guard let data = UserDefaults.standard.data(forKey: routinesCacheKey) else {
            print("ℹ️ [WATCH] No cached routines found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            routines = try decoder.decode([Routine].self, from: data)
            print("✅ [WATCH] Loaded \(routines.count) cached routines")
        } catch {
            print("❌ [WATCH] Failed to decode cached routines: \(error)")
        }
    }
    
    private func saveRoutinesToCache(_ data: Data) {
        UserDefaults.standard.set(data, forKey: routinesCacheKey)
        print("💾 [WATCH] Routines saved to cache")
    }
    
    // MARK: - Workout Management
    
    func startWorkout(routine: Routine) {
        // Convert RoutineExercise to ActiveWorkoutExercise
        let workoutExercises = routine.exercises.map { routineExercise -> ActiveWorkoutExercise in
            // Create simplified Exercise object from RoutineExercise
            let exercise = Exercise(
                id: routineExercise.exerciseId,
                name: routineExercise.exerciseName,
                category: .strength,
                muscleGroup: .back,
                equipment: .other,
                instructions: nil,
                videoUrl: nil,
                imageUrl: nil,
                gifUrl: nil,
                exerciseDbId: nil
            )
            
            return ActiveWorkoutExercise(
                exercise: exercise,
                targetSets: routineExercise.targetSets,
                targetReps: Int(routineExercise.targetReps),
                targetWeight: routineExercise.targetWeight,
                restTime: routineExercise.restSeconds,
                completedSets: []
            )
        }
        
        activeWorkout = ActiveWorkout(
            userId: "",
            routineId: routine.id,
            routineName: routine.name,
            routineDescription: routine.description,
            startTime: Date(),
            exercises: workoutExercises
        )
        
        startDate = Date()
        
        // Start HealthKit workout session
        startHealthKitWorkout()
        
        print("✅ [WATCH] Workout started: \(routine.name) with \(workoutExercises.count) exercises")
    }
    
    func startEmptyWorkout() {
        // Quick Start - empty workout sin rutina
        activeWorkout = ActiveWorkout(
            userId: "",
            routineId: nil,
            routineName: "Quick Start",
            routineDescription: nil,
            startTime: Date(),
            exercises: []
        )
        
        startDate = Date()
        
        // Start HealthKit workout session
        startHealthKitWorkout()
        
        print("✅ [WATCH] Empty workout started (Quick Start)")
    }
    
    func finishWorkout() {
        guard let workout = activeWorkout else { return }
        
        // End HealthKit workout
        endHealthKitWorkout()
        
        activeWorkout = nil
        heartRate = 0
        calories = 0
        additionalSetsByExercise.removeAll()
        
        print("✅ [WATCH] Workout finished")
    }
    
    func discardWorkout() {
        endHealthKitWorkout()
        
        activeWorkout = nil
        heartRate = 0
        calories = 0
        additionalSetsByExercise.removeAll()
        
        print("✅ [WATCH] Workout discarded")
    }
    
    // MARK: - Set Management
    
    func completeSet(exerciseIndex: Int, weight: Double, reps: Int) {
        guard var workout = activeWorkout else { return }
        
        let setNumber = workout.exercises[exerciseIndex].completedSets.count + 1
        let completedSet = CompletedSet(
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            setType: .working,
            rpe: nil,
            completedAt: Date()
        )
        
        workout.exercises[exerciseIndex].completedSets.append(completedSet)
        activeWorkout = workout
        
        // Start rest timer
        let restTime = workout.exercises[exerciseIndex].restTime
        if restTime > 0 {
            startRestTimer(duration: restTime)
        }
        
        // Sync to iPhone
        syncWorkoutToPhone()
        
        print("✅ [WATCH] Set completed: \(weight)lbs x \(reps) reps")
    }
    
    func removeLastCompletedSet(exerciseIndex: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard !workout.exercises[exerciseIndex].completedSets.isEmpty else { return }
        
        workout.exercises[exerciseIndex].completedSets.removeLast()
        activeWorkout = workout
        
        // Sync to iPhone
        syncWorkoutToPhone()
        
        print("🔄 [WATCH] Last set removed from exercise \(exerciseIndex)")
    }
    
    func removeCompletedSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count else { return }
        guard setIndex < workout.exercises[exerciseIndex].completedSets.count else { return }
        
        workout.exercises[exerciseIndex].completedSets.remove(at: setIndex)
        activeWorkout = workout
        
        // Sync to iPhone
        syncWorkoutToPhone()
        
        print("🔄 [WATCH] Set \(setIndex) removed from exercise \(exerciseIndex)")
    }
    
    func addSetSlot(exerciseIndex: Int) {
        additionalSetsByExercise[exerciseIndex, default: 0] += 1
        print("➕ [WATCH] Added set slot to exercise \(exerciseIndex). Total additional sets: \(additionalSetsByExercise[exerciseIndex] ?? 0)")
    }
    
    func getTotalSets(for exerciseIndex: Int) -> Int {
        guard let workout = activeWorkout,
              exerciseIndex < workout.exercises.count else { return 0 }
        
        let exercise = workout.exercises[exerciseIndex]
        let additionalSets = additionalSetsByExercise[exerciseIndex] ?? 0
        
        // Total sets = target + additional, pero al menos igual a completedSets.count
        return max(exercise.targetSets + additionalSets, exercise.completedSets.count)
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(duration: Int) {
        // Invalidar timer anterior si existe
        restTimer?.invalidate()
        restTimer = nil
        
        isResting = true
        restTimeRemaining = duration
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.restTimeRemaining -= 1
                
                if self.restTimeRemaining <= 0 {
                    timer.invalidate()
                    self.isResting = false
                    self.restTimer = nil
                }
            }
        }
    }
    
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
    }
    
    // MARK: - HealthKit Workout
    
    private func startHealthKitWorkout() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("❌ [WATCH] Failed to begin workout collection: \(error)")
                }
            }
            
            print("✅ [WATCH] HealthKit workout started")
        } catch {
            print("❌ [WATCH] Failed to start workout session: \(error)")
        }
    }
    
    private func endHealthKitWorkout() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("❌ [WATCH] Failed to end workout collection: \(error)")
            }
        }
        
        workoutBuilder?.finishWorkout { workout, error in
            if let error = error {
                print("❌ [WATCH] Failed to finish workout: \(error)")
            } else {
                print("✅ [WATCH] HealthKit workout saved")
            }
        }
    }
    
    // MARK: - Sync
    
    private func syncWorkoutToPhone() {
        // TODO: Implement sync to phone when needed
        print("🔄 [WATCH] Sync to phone (not yet implemented)")
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("🔄 [WATCH] Workout session state changed: \(toState.rawValue)")
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ [WATCH] Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }
                
                if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                    if let statistics = workoutBuilder.statistics(for: quantityType) {
                        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                        let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                        self.heartRate = Int(value)
                    }
                }
                
                if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    if let statistics = workoutBuilder.statistics(for: quantityType) {
                        let energyUnit = HKUnit.kilocalorie()
                        let value = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
                        self.calories = Int(value)
                    }
                }
            }
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }
}
