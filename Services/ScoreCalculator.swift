import Foundation
import HealthKit

class ScoreCalculator {
    static let shared = ScoreCalculator()
    
    private init() {}
    
    func calculateWeeklyScore(workouts: [HKWorkout], sleepSamples: [HKCategorySample]) async -> ScoreComponents {
        let consistency = await calculateConsistency(workouts: workouts)
        let volume = await calculateVolume(workouts: workouts)
        let intensity = await calculateIntensity(workouts: workouts)
        let recovery = calculateRecovery(sleepSamples: sleepSamples)
        
        return ScoreComponents(
            consistency: consistency,
            volume: volume,
            intensity: intensity,
            recovery: recovery
        )
    }
    
    private func calculateConsistency(workouts: [HKWorkout]) async -> Int {
        let calendar = Calendar.current
        var daysWithWorkouts = Set<DateComponents>()
        
        for workout in workouts {
            let components = calendar.dateComponents([.year, .month, .day], from: workout.startDate)
            daysWithWorkouts.insert(components)
        }
        
        let uniqueDays = min(daysWithWorkouts.count, 5)
        return uniqueDays * 8
    }
    
    private func calculateVolume(workouts: [HKWorkout]) async -> Int {
        let totalMinutes = workouts.reduce(0.0) { total, workout in
            total + workout.duration / 60.0
        }
        
        let clampedMinutes = min(totalMinutes, 250.0)
        return Int(clampedMinutes * 0.1)
    }
    
    private func calculateIntensity(workouts: [HKWorkout]) async -> Int {
        var totalCalories = 0.0
        
        for workout in workouts {
            if let energy = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                totalCalories += energy
            } else {
                let calories = try? await HealthKitManager.shared.fetchActiveEnergy(for: workout)
                totalCalories += calories ?? 0
            }
        }
        
        let clampedCalories = min(totalCalories, 1000.0)
        return Int(clampedCalories * 0.025)
    }
    
    private func calculateRecovery(sleepSamples: [HKCategorySample]) -> Int {
        let calendar = Calendar.current
        var sleepByDate: [Date: TimeInterval] = [:]
        
        for sample in sleepSamples {
            guard sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                  sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue else {
                continue
            }
            
            let startOfDay = calendar.startOfDay(for: sample.startDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            sleepByDate[startOfDay, default: 0] += duration
        }
        
        let nightsWithGoodSleep = sleepByDate.values.filter { $0 >= 6.5 * 3600 }.count
        let clampedNights = min(nightsWithGoodSleep, 5)
        
        return clampedNights * 2
    }
}
