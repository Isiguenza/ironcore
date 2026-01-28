import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        print("🏥 [HEALTHKIT] Requesting authorization...")
        
        guard isHealthDataAvailable else {
            print("❌ [HEALTHKIT] HealthKit not available")
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        print("🏥 [HEALTHKIT] Requesting read access for: Workouts, Active Energy, Exercise Time, Sleep")
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        // Check authorization status
        let workoutStatus = healthStore.authorizationStatus(for: .workoutType())
        print("🏥 [HEALTHKIT] Workout authorization status: \(workoutStatus.rawValue)")
        print("✅ [HEALTHKIT] Authorization completed")
    }
    
    func fetchWeeklyWorkouts(startDate: Date) async throws -> [HKWorkout] {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? Date()
        
        print("🏥 [HEALTHKIT] Querying workouts from \(startDate) to \(endDate)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    print("❌ [HEALTHKIT] Error fetching workouts: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                print("🏥 [HEALTHKIT] Query returned \(workouts.count) workouts")
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchActiveEnergy(for workout: HKWorkout) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchWeeklySleep(startDate: Date) async throws -> [HKCategorySample] {
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? Date()
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let sleepSamples = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: sleepSamples)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed:
            return "Failed to authorize HealthKit access"
        }
    }
}
