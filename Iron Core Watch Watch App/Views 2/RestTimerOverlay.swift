import SwiftUI

struct RestTimerOverlay: View {
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .blur(radius: 10)
            
            VStack(spacing: 16) {
                Button(action: {
                    workoutManager.skipRest()
                }) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.2))
                        .cornerRadius(20)
                }
                
                // Large timer
                Text(formatTime(workoutManager.restTimeRemaining))
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.neonGreen)
                    .monospacedDigit()
                
                // Progress bar
                ProgressView(value: Double(workoutManager.restTimeRemaining), total: 180.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .neonGreen))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                // Next set info (if available)
                if let workout = workoutManager.activeWorkout,
                   let currentExercise = workout.exercises.first(where: { $0.completedSets.count < $0.targetSets }) {
                    VStack(spacing: 4) {
                        Text("Next Set")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(currentExercise.exercise.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        if let weight = currentExercise.targetWeight, let reps = currentExercise.targetReps {
                            Text("Set \(currentExercise.completedSets.count + 1)/\(currentExercise.targetSets): \(String(format: "%.1f", weight))lbs × \(reps)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Time adjustment buttons
                HStack(spacing: 20) {
                    Button(action: {
                        adjustRestTime(by: -15)
                    }) {
                        Text("-15s")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 40)
                            .background(Color(white: 0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        adjustRestTime(by: 15)
                    }) {
                        Text("+15s")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 40)
                            .background(Color(white: 0.2))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func adjustRestTime(by seconds: Int) {
        let newTime = max(0, workoutManager.restTimeRemaining + seconds)
        workoutManager.restTimeRemaining = newTime
    }
}
