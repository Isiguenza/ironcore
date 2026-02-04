import SwiftUI

struct ExerciseDetailView: View {
    let exercise: ActiveWorkoutExercise
    let exerciseIndex: Int

    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Wheel Picker State
    @State private var weightValue: Double = 0.0
    @State private var repsValue: Double = 0.0

    @State private var currentSetIndex = 0
    @State private var showingExerciseActions = false

    @FocusState private var focusedWheel: WheelField?

    enum WheelField {
        case weight, reps
    }

    // MARK: - Wheel Data
    private let weightValues: [Double] = stride(from: 0.0, through: 500.0, by: 2.5).map { $0 }
    private let repsValues: [Int] = Array(0...99)

    var body: some View {
        VStack(spacing: 0) {
            // Set number
            Text("Set \(currentSetIndex + 1) of \(exercise.targetSets)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 8)
                .padding(.bottom, 12)

            Spacer()

            // Wheel pickers (touch + crown)
            pickersSection

            Spacer()

            // Navigation buttons (glass)
            navigationButtons

            Spacer()

            // Set options label (tap target could open sheet later)
            Text("Set Options")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
        }
        .padding()
        .background(Color.black)
        .navigationTitle(exercise.exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text("\(WatchWorkoutManager.shared.heartRate)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .sheet(isPresented: $showingExerciseActions) {
            exerciseActionsSheet
        }
    }

    // MARK: - Sections

    private var pickersSection: some View {
        HStack(spacing: 16) {

            // WEIGHT (LBS)
            VStack(spacing: 6) {
                Text("LBS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)

                Text(String(format: "%.1f", weightValue))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(white: 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                focusedWheel == .weight ? Color.neonGreen : Color.white.opacity(0.2),
                                lineWidth: focusedWheel == .weight ? 1.5 : 1
                            )
                    )
                    .focusable(true)
                    .focused($focusedWheel, equals: .weight)
                    .digitalCrownRotation($weightValue, from: 0.0, through: 500.0, by: 2.5, sensitivity: .medium)
                    .onTapGesture { focusedWheel = .weight }
            }

            // REPS
            VStack(spacing: 6) {
                Text("REPS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)

                Text("\(Int(repsValue))")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(white: 0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                focusedWheel == .reps ? Color.neonGreen : Color.white.opacity(0.2),
                                lineWidth: focusedWheel == .reps ? 1.5 : 1
                            )
                    )
                    .focusable(true)
                    .focused($focusedWheel, equals: .reps)
                    .digitalCrownRotation($repsValue, from: 1.0, through: 99.0, by: 1.0, sensitivity: .medium)
                    .onTapGesture { focusedWheel = .reps }
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
                    .frame(width: 30, height: 30)
                   
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.secondary)
            .disabled(currentSetIndex == 0)
            .opacity(currentSetIndex == 0 ? 0.35 : 1.0)

            // Complete set
            Button(action: completeSet) {
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(width: 30, height: 30)
                    
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.neonGreen)

            // Next set
            Button(action: nextSet) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.secondary)
            .disabled(currentSetIndex >= exercise.targetSets - 1)
            .opacity(currentSetIndex >= exercise.targetSets - 1 ? 0.35 : 1.0)
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
            .buttonStyle(.plain)

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
            .buttonStyle(.plain)

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
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black)
    }

    // MARK: - Helpers

    private func setupInitialValues() {
        currentSetIndex = exercise.completedSets.count

        let initialWeight: Double
        let initialReps: Int

        if currentSetIndex > 0, let lastSet = exercise.completedSets.last {
            initialWeight = lastSet.weight
            initialReps = lastSet.reps
        } else {
            initialWeight = exercise.targetWeight ?? 0.0
            initialReps = exercise.targetReps ?? 10
        }

        weightValue = initialWeight
        repsValue = Double(min(max(initialReps, 0), 99))

        focusedWheel = .weight
    }

    private func completeSet() {
        workoutManager.completeSet(exerciseIndex: exerciseIndex, weight: weightValue, reps: Int(repsValue))

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
                // sync wheels to previous set
                weightValue = previousSet.weight
                repsValue = Double(min(max(previousSet.reps, 0), 99))
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
