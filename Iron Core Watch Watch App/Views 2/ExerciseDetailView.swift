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
        List {
           
            
            // Picker card
       
            VStack(alignment: .leading, spacing: 12) {
                    
                VStack(alignment: .leading, spacing: 4){
                        Text(exercise.exercise.name)
                            .font(.system(size: 12))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text("set \(currentSetIndex + 1)/\(exercise.targetSets)")
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        
                    }
                    
                    // Pickers - horizontal layout
                    pickersSection
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .listRowBackground(Color.clear)
            
            // Action buttons
                actionButtonsSection
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack(alignment: .trailing){
                    HStack(spacing: 4) {
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(delay: 0.4)))
                        Text("\(WatchWorkoutManager.shared.heartRate)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    HStack(spacing: 4) {
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        Text("\(WatchWorkoutManager.shared.calories)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                    }
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
        HStack(spacing: 10) {
            // WEIGHT
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 9, weight: .semibold))
                    Text("LBS")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.gray)

                Text(String(format: "%.1f", weightValue))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(focusedWheel == .weight ? .neonGreen : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(focusedWheel == .weight ? Color.neonGreen.opacity(0.15) : Color(white: 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                focusedWheel == .weight ? 
                                    LinearGradient(colors: [Color.neonGreen, Color.neonGreen.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: focusedWheel == .weight ? 2.5 : 1
                            )
                    )
                    .focusable(true)
                    .focused($focusedWheel, equals: .weight)
                    .digitalCrownRotation($weightValue, from: 0.0, through: 500.0, by: 2.5, sensitivity: .medium)
                    .onTapGesture { focusedWheel = .weight }
            }

            // REPS
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: "repeat")
                        .font(.system(size: 9, weight: .semibold))
                    Text("REPS")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.gray)

                Text("\(Int(repsValue))")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(focusedWheel == .reps ? .neonGreen : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(focusedWheel == .reps ? Color.neonGreen.opacity(0.15) : Color(white: 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                focusedWheel == .reps ? 
                                    LinearGradient(colors: [Color.neonGreen, Color.neonGreen.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: focusedWheel == .reps ? 2.5 : 1
                            )
                    )
                    .focusable(true)
                    .focused($focusedWheel, equals: .reps)
                    .digitalCrownRotation($repsValue, from: 1.0, through: 99.0, by: 1.0, sensitivity: .medium)
                    .onTapGesture { focusedWheel = .reps }
            }
        }
    }

    private var setProgressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<exercise.targetSets, id: \.self) { index in
                Circle()
                    .fill(index <= currentSetIndex ? Color.neonGreen : Color.white.opacity(0.2))
                    .frame(width: index == currentSetIndex ? 6 : 4, height: index == currentSetIndex ? 6 : 4)
                    .overlay(
                        Circle()
                            .stroke(index == currentSetIndex ? Color.neonGreen : Color.clear, lineWidth: 1.5)
                            .frame(width: 10, height: 10)
                    )
                
                Spacer()
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            
            // Secondary actions
            HStack(spacing: 10) {
                // Previous
                Button(action: previousSet) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(white: 0.16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(currentSetIndex == 0)
                .opacity(currentSetIndex == 0 ? 0.3 : 1.0)
                
                // Complete Set (checkmark)
                Button(action: completeSet) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.neonGreen, Color.neonGreen.opacity(0.85)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.neonGreen.opacity(0.3), radius: 6, x: 0, y: 2)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // Next
                Button(action: nextSet) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(white: 0.16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(currentSetIndex >= exercise.targetSets - 1)
                .opacity(currentSetIndex >= exercise.targetSets - 1 ? 0.3 : 1.0)
            }
            // Add Set button
            Button(action: {
                // Add new set action
                completeSet()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Add Set")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            
            
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
