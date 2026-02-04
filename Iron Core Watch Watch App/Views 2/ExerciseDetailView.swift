import SwiftUI

struct ExerciseDetailView: View {
    let exercise: ActiveWorkoutExercise
    let exerciseIndex: Int
    
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 0.0
    @State private var reps: Double = 0.0
    @State private var currentSetIndex = 0
    @State private var showingExerciseActions = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con back button, nombre y heart rate
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color(white: 0.2)))
                }
                
                Spacer()
                
                // Heart rate
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text("\(WatchWorkoutManager.shared.heartRate)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Exercise name and set number
            VStack(spacing: 4) {
                Text(exercise.exercise.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Set \(currentSetIndex + 1) of \(exercise.targetSets)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            // Weight and Reps pickers
            pickersSection
            
            Spacer()
            
            // Navigation and complete buttons
            navigationButtons
            
            Spacer()
            
            // Exercise action text
            Text("Set Options")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .padding()
        .background(Color.black)
        .onAppear {
            setupInitialValues()
        }
        .sheet(isPresented: $showingExerciseActions) {
            exerciseActionsSheet
        }
    }
    
    
    private var pickersSection: some View {
        HStack(spacing: 12) {
            // Weight Picker
            VStack(spacing: 4) {
                Text("LBS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text(String(format: "%.1f", weight))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue, lineWidth: 2)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black))
                    )
                    .focusable(true)
                    .digitalCrownRotation($weight, from: 0.0, through: 500.0, by: 2.5, sensitivity: .medium)
                    .focused($focusedField, equals: .weight)
            }
            
            // Reps Picker
            VStack(spacing: 4) {
                Text("REPS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text("\(Int(reps))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black))
                    )
                    .focusable(true)
                    .digitalCrownRotation($reps, from: 0.0, through: 99.0, by: 1.0, sensitivity: .medium)
                    .focused($focusedField, equals: .reps)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Previous set
            Button(action: previousSet) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color(white: 0.2)))
            }
            .disabled(currentSetIndex == 0)
            .opacity(currentSetIndex == 0 ? 0.3 : 1.0)
            
            // Complete set - Blue checkmark
            Button(action: completeSet) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.blue)
                    )
            }
            
            // Next set
            Button(action: nextSet) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color(white: 0.2)))
            }
            .disabled(currentSetIndex >= exercise.targetSets - 1)
            .opacity(currentSetIndex >= exercise.targetSets - 1 ? 0.3 : 1.0)
        }
    }
    
    
    private var exerciseActionsSheet: some View {
        VStack(spacing: 16) {
            Text("Exercise Options")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            Button(action: {
                showingExerciseActions = false
                // TODO: Add exercise
            }) {
                Text("Add Exercise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: {
                showingExerciseActions = false
                // TODO: Replace exercise
            }) {
                Text("Replace Exercise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: {
                showingExerciseActions = false
                // TODO: Delete exercise
            }) {
                Text("Delete Exercise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.black)
    }
    
    private func setupInitialValues() {
        currentSetIndex = exercise.completedSets.count
        
        if currentSetIndex > 0, let lastSet = exercise.completedSets.last {
            weight = lastSet.weight
            reps = Double(lastSet.reps)
        } else {
            weight = exercise.targetWeight ?? 0.0
            reps = Double(exercise.targetReps ?? 10)
        }
        
        focusedField = .weight
    }
    
    private func completeSet() {
        workoutManager.completeSet(exerciseIndex: exerciseIndex, weight: weight, reps: Int(reps))
        
        if currentSetIndex < exercise.targetSets - 1 {
            currentSetIndex += 1
        } else {
            dismiss()
        }
    }
    
    private func previousSet() {
        if currentSetIndex > 0 {
            currentSetIndex -= 1
            if let previousSet = exercise.completedSets[safe: currentSetIndex] {
                weight = previousSet.weight
                reps = Double(previousSet.reps)
            }
        }
    }
    
    private func nextSet() {
        if currentSetIndex < exercise.targetSets - 1 {
            currentSetIndex += 1
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
