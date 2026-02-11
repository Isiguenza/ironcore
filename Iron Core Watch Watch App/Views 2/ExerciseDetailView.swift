import SwiftUI
import WatchKit

struct ExerciseDetailView: View {
    let exercise: ActiveWorkoutExercise
    let exerciseIndex: Int

    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Exercise Navigation State
    @State private var currentExerciseIndex: Int
    
    // MARK: - Wheel Picker State
    @State private var weightValue: Double = 0.0
    @State private var repsValue: Double = 0.0

    @State private var currentSetIndex = 0
    @State private var showingExerciseActions = false
    @State private var showingSetOptions = false
    @State private var showingRestTimer = false

    @State private var activeWheel: WheelField?
    @FocusState private var isCrownFocused: Bool
    @State private var lastDragY: CGFloat = 0
    @State private var dragAccumulator: CGFloat = 0
    
    init(exercise: ActiveWorkoutExercise, exerciseIndex: Int) {
        self.exercise = exercise
        self.exerciseIndex = exerciseIndex
        _currentExerciseIndex = State(initialValue: exerciseIndex)
        _currentSetIndex = State(initialValue: exercise.completedSets.count)
    }

    enum WheelField {
        case weight, reps
    }

    // MARK: - Wheel Data
    private let weightValues: [Double] = stride(from: 0.0, through: 500.0, by: 2.5).map { $0 }
    private let repsValues: [Int] = Array(0...99)

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Picker card
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let workout = workoutManager.activeWorkout,
                           currentExerciseIndex < workout.exercises.count {
                            let currentExercise = workout.exercises[currentExerciseIndex]
                            
                            Text(currentExercise.exercise.name)
                                .font(.system(size: 12))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
                                    Text("set \(currentSetIndex + 1)/\(totalSets)")
                                        .font(.system(size: 10))
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .foregroundColor(isCurrentSetCompleted() ? .neonGreen : .gray)
                                    
                                    if isCurrentSetCompleted() {
                                        Circle()
                                            .fill(Color.neonGreen)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                
                                Spacer()
                                
                                let lastWeight = getLastWeight(for: currentExercise.exerciseId)
                                Text("Last \(String(format: "%.1f", lastWeight))")
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                        }
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
                
                // Action buttons
                actionButtonsSection
                    .padding(.horizontal, 8)
                
                // Add Set button
                addSetButton
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                
                // Set Options button
                setOptionsButton
                    .padding(.horizontal, 8)
                
                // Exercise Options button
                exerciseOptionsButton
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 4)
            .onTapGesture {
                if activeWheel != nil {
                    activeWheel = nil
                }
            }
        }
        .scrollDisabled(activeWheel != nil)
        .highPriorityGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    guard let wheel = activeWheel else { return }
                    let currentY = value.translation.height
                    let delta = currentY - lastDragY
                    lastDragY = currentY
                    dragAccumulator += delta
                    
                    let threshold: CGFloat = 25
                    if abs(dragAccumulator) >= threshold {
                        let steps = Int(dragAccumulator / threshold)
                        dragAccumulator -= CGFloat(steps) * threshold
                        
                        if wheel == .weight {
                            weightValue = roundToHalf(max(0, min(500, weightValue - Double(steps) * 0.5)))
                        } else {
                            repsValue = max(1, min(99, repsValue - Double(steps)))
                        }
                        WKInterfaceDevice.current().play(.click)
                    }
                }
                .onEnded { _ in
                    lastDragY = 0
                    dragAccumulator = 0
                }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VStack(alignment: .leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(delay: 0.4)))
                        Text("\(WatchWorkoutManager.shared.heartRate)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("\(WatchWorkoutManager.shared.calories)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .onChange(of: activeWheel) { newValue in
            let shouldFocus = (newValue != nil)
            isCrownFocused = shouldFocus
            print("[FOCUS] activeWheel: \(String(describing: newValue)), isCrownFocused: \(shouldFocus)")
        }
        .onChange(of: workoutManager.isResting) { isResting in
            if !isResting && showingRestTimer {
                showingRestTimer = false
            }
        }
        .onChange(of: currentExerciseIndex) { _ in
            setupInitialValues()
        }
        .onDisappear {
            showingRestTimer = false
        }
        .sheet(isPresented: $showingSetOptions) {
            setOptionsSheet
        }
        .sheet(isPresented: $showingExerciseActions) {
            exerciseActionsSheet
        }
        .fullScreenCover(isPresented: $showingRestTimer) {
            RestTimerOverlay()
                .interactiveDismissDisabled(false)
                .presentationDragIndicator(.visible)
                .onDisappear {
                    workoutManager.skipRest()
                }
        }
    }

    // MARK: - Sections
    
    private func pickerTile(titleIcon: String, titleText: String, valueText: String, isFocused: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: titleIcon)
                    .font(.system(size: 9, weight: .semibold))
                Text(titleText)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.gray)

            Text(valueText)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isFocused ? .neonGreen : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isFocused ? Color.neonGreen.opacity(0.15) : Color(white: 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isFocused ?
                                LinearGradient(colors: [Color.neonGreen, Color.neonGreen.opacity(0.5)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.15)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: isFocused ? 2.5 : 1
                        )
                )
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private var crownBinding: Binding<Double> {
        Binding(
            get: {
                activeWheel == .weight ? weightValue : repsValue
            },
            set: { newValue in
                if activeWheel == .weight {
                    weightValue = roundToHalf(newValue)
                } else if activeWheel == .reps {
                    repsValue = newValue
                }
            }
        )
    }

    private var pickersSection: some View {
        HStack(spacing: 10) {
            // Weight picker
            Button {
                let before = activeWheel
                activeWheel = (activeWheel == .weight) ? nil : .weight
                print("[PICKER] Weight tapped. Before: \(String(describing: before)), After: \(String(describing: activeWheel))")
            } label: {
                pickerTile(
                    titleIcon: "scalemass",
                    titleText: "LBS",
                    valueText: String(format: "%.1f", weightValue),
                    isFocused: activeWheel == .weight
                )
            }
            .buttonStyle(.plain)

            // Reps picker
            Button {
                let before = activeWheel
                activeWheel = (activeWheel == .reps) ? nil : .reps
                print("[PICKER] Reps tapped. Before: \(String(describing: before)), After: \(String(describing: activeWheel))")
            } label: {
                pickerTile(
                    titleIcon: "repeat",
                    titleText: "REPS",
                    valueText: "\(Int(repsValue))",
                    isFocused: activeWheel == .reps
                )
            }
            .buttonStyle(.plain)
        }
        .focusable(activeWheel != nil)
        .focused($isCrownFocused)
        .digitalCrownRotation(
            crownBinding,
            from: activeWheel == .reps ? 1.0 : 0.0,
            through: activeWheel == .reps ? 99.0 : 500.0,
            by: activeWheel == .reps ? 1.0 : 0.5,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
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
        HStack(spacing: 3) {
            // Previous
            Button(action: previousSet) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
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
            
            // Complete Set
            Button(action: completeSet) {
                let isCompleted = isCurrentSetCompleted()
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isCompleted ?
                                        [Color.neonGreen, Color.neonGreen.opacity(0.85)] :
                                        [Color.gray, Color.gray.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: (isCompleted ? Color.neonGreen : Color.gray).opacity(0.3), radius: 6, x: 0, y: 2)
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
                    .frame(height: 30)
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
        }
    }
    
    private var addSetButton: some View {
        Button(action: addSet) {
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(white: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var setOptionsButton: some View {
        Button(action: { showingSetOptions = true }) {
            HStack(spacing: 8) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17, weight: .semibold))
                Text("Set Options")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
    }
    
    private var exerciseOptionsButton: some View {
        Button(action: { showingExerciseActions = true }) {
            HStack(spacing: 8) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17, weight: .semibold))
                Text("Exercise Options")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
    }

    private var setOptionsSheet: some View {
        VStack(spacing: 16) {
            Text("Set Options")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)

            Button(action: {
                showingSetOptions = false
                deleteCurrentSet()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Set")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.16))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showingSetOptions = false
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black)
    }
    
    private var exerciseActionsSheet: some View {
        VStack(spacing: 16) {
            Text("Exercise Options")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)

            Button(action: {
                showingExerciseActions = false
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Exercise")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.16))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showingExerciseActions = false
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Replace Exercise")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.16))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            Button(action: {
                showingExerciseActions = false
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Exercise")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(white: 0.16))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showingExerciseActions = false
            }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(white: 0.12))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black)
    }
    
    private func deleteCurrentSet() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let currentExercise = workout.exercises[currentExerciseIndex]
        let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
        
        guard totalSets > 1 else { return }
        
        if currentSetIndex < currentExercise.completedSets.count {
            workoutManager.removeCompletedSet(exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
        }
        
        let additionalSets = workoutManager.additionalSetsByExercise[currentExerciseIndex] ?? 0
        if additionalSets > 0 {
            workoutManager.additionalSetsByExercise[currentExerciseIndex] = additionalSets - 1
            
            let newTotalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            if currentSetIndex >= newTotalSets {
                currentSetIndex = max(0, newTotalSets - 1)
            }
            setupInitialValues()
        }
    }

    // MARK: - Helpers
    
    private func getLastWeight(for exerciseId: String) -> Double {
        let key = "lastWeight_\(exerciseId)"
        return UserDefaults.standard.double(forKey: key)
    }
    
    private func saveLastWeight(_ weight: Double, for exerciseId: String) {
        let key = "lastWeight_\(exerciseId)"
        UserDefaults.standard.set(weight, forKey: key)
    }
    
    private func roundToHalf(_ value: Double) -> Double {
        return round(value * 2.0) / 2.0
    }
    
    private func isCurrentSetCompleted() -> Bool {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return false }
        
        let currentExercise = workout.exercises[currentExerciseIndex]
        return currentSetIndex < currentExercise.completedSets.count
    }
    
    private func setupInitialValues() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let currentExercise = workout.exercises[currentExerciseIndex]
        
        let initialWeight: Double
        let initialReps: Int

        if currentSetIndex < currentExercise.completedSets.count {
            let completedSet = currentExercise.completedSets[currentSetIndex]
            initialWeight = completedSet.weight
            initialReps = completedSet.reps
        } else if currentExercise.completedSets.count > 0, let lastSet = currentExercise.completedSets.last {
            initialWeight = lastSet.weight
            initialReps = lastSet.reps
        } else {
            let lastWeight = getLastWeight(for: currentExercise.exerciseId)
            initialWeight = lastWeight > 0 ? lastWeight : (currentExercise.targetWeight ?? 0.0)
            initialReps = currentExercise.targetReps ?? 10
        }

        weightValue = roundToHalf(initialWeight)
        repsValue = Double(min(max(initialReps, 0), 99))
    }

    private func completeSet() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let currentExercise = workout.exercises[currentExerciseIndex]
        let isAlreadyCompleted = currentSetIndex < currentExercise.completedSets.count
        
        if isAlreadyCompleted {
            workoutManager.removeCompletedSet(exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
            setupInitialValues()
        } else {
            let roundedWeight = roundToHalf(weightValue)
            workoutManager.completeSet(exerciseIndex: currentExerciseIndex, weight: roundedWeight, reps: Int(repsValue))
            saveLastWeight(roundedWeight, for: currentExercise.exerciseId)
            
            let shouldShowRest = currentExercise.restTime > 0
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            
            if currentSetIndex < currentExercise.targetSets - 1 {
                currentSetIndex += 1
                setupInitialValues()
                if shouldShowRest { showingRestTimer = true }
            } else if currentSetIndex < totalSets - 1 {
                currentSetIndex += 1
                setupInitialValues()
                if shouldShowRest { showingRestTimer = true }
            } else if currentExerciseIndex < workout.exercises.count - 1 {
                currentExerciseIndex += 1
                currentSetIndex = 0
                setupInitialValues()
                if shouldShowRest { showingRestTimer = true }
            } else {
                setupInitialValues()
                if shouldShowRest { showingRestTimer = true }
            }
        }
    }

    private func previousSet() {
        guard let workout = workoutManager.activeWorkout else { return }
        
        if currentSetIndex > 0 {
            currentSetIndex -= 1
            setupInitialValues()
        } else if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            currentSetIndex = totalSets - 1
            setupInitialValues()
        } else {
            currentExerciseIndex = workout.exercises.count - 1
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            currentSetIndex = totalSets - 1
            setupInitialValues()
        }
    }

    private func addSet() {
        workoutManager.addSetSlot(exerciseIndex: currentExerciseIndex)
    }
    
    private func nextSet() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
        
        if currentSetIndex < totalSets - 1 {
            currentSetIndex += 1
            setupInitialValues()
        } else if currentExerciseIndex < workout.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
            setupInitialValues()
        } else {
            currentExerciseIndex = 0
            currentSetIndex = 0
            setupInitialValues()
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
