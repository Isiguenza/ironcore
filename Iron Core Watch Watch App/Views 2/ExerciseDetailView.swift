import SwiftUI

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
    @State private var showingRestTimer = false

    @FocusState private var focusedWheel: WheelField?
    
    init(exercise: ActiveWorkoutExercise, exerciseIndex: Int) {
        self.exercise = exercise
        self.exerciseIndex = exerciseIndex
        _currentExerciseIndex = State(initialValue: exerciseIndex)
        // Iniciar en el primer set no completado
        _currentSetIndex = State(initialValue: exercise.completedSets.count)
    }

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
                        if let workout = workoutManager.activeWorkout,
                           currentExerciseIndex < workout.exercises.count {
                            let currentExercise = workout.exercises[currentExerciseIndex]
                            
                            Text(currentExercise.exercise.name)
                                .font(.system(size: 12))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
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
        .onChange(of: workoutManager.isResting) { isResting in
            // Cuando el rest timer termina naturalmente, cerrar el overlay
            if !isResting && showingRestTimer {
                showingRestTimer = false
            }
        }
        .onChange(of: currentExerciseIndex) { _ in
            // Solo actualizar los valores del picker, NO cambiar currentSetIndex
            // El currentSetIndex ya se maneja correctamente en nextSet/previousSet/completeSet
            setupInitialValues()
        }
        .scrollDisabled(focusedWheel != nil)
        .onDisappear {
            // Limpiar estado del rest timer al salir
            showingRestTimer = false
        }
        .sheet(isPresented: $showingExerciseActions) {
            exerciseActionsSheet
        }
        .fullScreenCover(isPresented: $showingRestTimer) {
            ZStack(alignment: .topTrailing) {
                RestTimerOverlay()
                
                // Botón X para cerrar y omitir
                Button(action: {
                    workoutManager.skipRest()
                    showingRestTimer = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                .buttonStyle(.plain)
                .padding(16)
            }
            .interactiveDismissDisabled()
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
                    .font(.system(size: 24, weight: .bold))
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
                    .focusable(true) { isFocused in
                        if isFocused {
                            focusedWheel = .weight
                        }
                    }
                    .focused($focusedWheel, equals: .weight)
                    .digitalCrownRotation($weightValue, from: 0.0, through: 500.0, by: 0.5, sensitivity: .low, isContinuous: false)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                focusedWheel = .weight
                                let delta = -value.translation.height / 10.0
                                let newValue = weightValue + (delta * 0.5)
                                weightValue = max(0.0, min(500.0, newValue))
                            }
                    )
                    .onTapGesture { 
                        focusedWheel = .weight
                    }
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
                    .font(.system(size: 24, weight: .bold))
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
                    .focusable(true) { isFocused in
                        if isFocused {
                            focusedWheel = .reps
                        }
                    }
                    .focused($focusedWheel, equals: .reps)
                    .digitalCrownRotation($repsValue, from: 1.0, through: 99.0, by: 1.0, sensitivity: .low, isContinuous: false)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                focusedWheel = .reps
                                let delta = -value.translation.height / 10.0
                                let newValue = repsValue + delta
                                repsValue = max(1.0, min(99.0, newValue))
                            }
                    )
                    .onTapGesture { 
                        focusedWheel = .reps
                    }
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
                
                // Complete Set (checkmark) - con toggle
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
                    let isLastSetOfLastExercise = {
                        guard let workout = workoutManager.activeWorkout else { return true }
                        return currentExerciseIndex >= workout.exercises.count - 1 && 
                               currentSetIndex >= exercise.targetSets - 1
                    }()
                    
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
            // Add Set button
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
        
        // NO cambiar currentSetIndex aquí, solo actualizar los valores del picker
        let initialWeight: Double
        let initialReps: Int

        // Si el set actual ya está completado, usa esos valores
        if currentSetIndex < currentExercise.completedSets.count {
            let completedSet = currentExercise.completedSets[currentSetIndex]
            initialWeight = completedSet.weight
            initialReps = completedSet.reps
        }
        // Si no está completado, usa el último set completado como referencia
        else if currentExercise.completedSets.count > 0, let lastSet = currentExercise.completedSets.last {
            initialWeight = lastSet.weight
            initialReps = lastSet.reps
        }
        // Si no hay sets completados, usa los valores target
        else {
            initialWeight = currentExercise.targetWeight ?? 0.0
            initialReps = currentExercise.targetReps ?? 10
        }

        weightValue = initialWeight
        repsValue = Double(min(max(initialReps, 0), 99))

        focusedWheel = .weight
    }

    private func completeSet() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let currentExercise = workout.exercises[currentExerciseIndex]
        
        // Check si este set ya está completado (toggle)
        let isAlreadyCompleted = currentSetIndex < currentExercise.completedSets.count
        
        if isAlreadyCompleted {
            // Desmarcar: remover ESTE set específico, no el último
            workoutManager.removeCompletedSet(exerciseIndex: currentExerciseIndex, setIndex: currentSetIndex)
            // Actualizar valores del picker
            setupInitialValues()
        } else {
            // Marcar como completado
            workoutManager.completeSet(exerciseIndex: currentExerciseIndex, weight: weightValue, reps: Int(repsValue))
            
            // Mostrar rest timer si aplica ANTES de avanzar
            let shouldShowRest = currentExercise.restTime > 0
            
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            
            // Avanzar al siguiente set o ejercicio
            if currentSetIndex < currentExercise.targetSets - 1 {
                // Hay más sets target en este ejercicio
                currentSetIndex += 1
                setupInitialValues()
                
                if shouldShowRest {
                    showingRestTimer = true
                }
            } else if currentSetIndex < totalSets - 1 {
                // Hay sets extra, avanzar
                currentSetIndex += 1
                setupInitialValues()
                
                if shouldShowRest {
                    showingRestTimer = true
                }
            } else if currentExerciseIndex < workout.exercises.count - 1 {
                // Ir al siguiente ejercicio
                currentExerciseIndex += 1
                currentSetIndex = 0
                setupInitialValues()
                
                if shouldShowRest {
                    showingRestTimer = true
                }
            } else {
                // Último set del último ejercicio - no hacer nada
                setupInitialValues()
                
                if shouldShowRest {
                    showingRestTimer = true
                }
            }
        }
    }

    private func previousSet() {
        guard let workout = workoutManager.activeWorkout else { return }
        
        if currentSetIndex > 0 {
            // Retroceder dentro del mismo ejercicio
            currentSetIndex -= 1
            setupInitialValues()
        } else if currentExerciseIndex > 0 {
            // Retroceder al ejercicio anterior
            currentExerciseIndex -= 1
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            currentSetIndex = totalSets - 1
            setupInitialValues()
        } else {
            // Estamos en el primer set del primer ejercicio
            // Navegación circular: ir al último ejercicio
            currentExerciseIndex = workout.exercises.count - 1
            let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
            currentSetIndex = totalSets - 1
            setupInitialValues()
        }
    }

    private func addSet() {
        // Añadir un slot de set adicional sin cambiar de posición
        workoutManager.addSetSlot(exerciseIndex: currentExerciseIndex)
    }
    
    private func nextSet() {
        guard let workout = workoutManager.activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let totalSets = workoutManager.getTotalSets(for: currentExerciseIndex)
        
        if currentSetIndex < totalSets - 1 {
            // Avanzar al siguiente set del mismo ejercicio
            currentSetIndex += 1
            setupInitialValues()
        } else if currentExerciseIndex < workout.exercises.count - 1 {
            // Si ya estamos en el último set, avanzar al siguiente ejercicio
            currentExerciseIndex += 1
            currentSetIndex = 0
            setupInitialValues()
        } else {
            // Estamos en el último set del último ejercicio
            // Navegación circular: ir al primer ejercicio
            currentExerciseIndex = 0
            currentSetIndex = 0
            setupInitialValues()
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
