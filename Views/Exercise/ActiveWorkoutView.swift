import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var restTimer = 0
    @State private var isResting = false
    @State private var showExerciseLibrary = false
    @State private var showFinishConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                
                VStack(spacing: 0) {
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            if let workout = workoutViewModel.activeWorkout {
                                ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                                    ExerciseCard(
                                        exercise: exercise,
                                        exerciseIndex: index,
                                        workoutViewModel: workoutViewModel,
                                        onSetComplete: { startRestTimer() }
                                    )
                                }
                            }
                            
                            Button(action: { showExerciseLibrary = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                    Text("Add exercise")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.neonGreen))
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .padding(.vertical)
                    }
                    
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFinishConfirmation = true }) {
                        Text("Finish")
                            .foregroundColor(.neonGreen)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView(workoutViewModel: workoutViewModel) { exercise in
                    addExerciseToWorkout(exercise)
                }
            }
            .alert("Finish Workout", isPresented: $showFinishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Finish", role: .destructive) {
                    Task {
                        await workoutViewModel.finishWorkout()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to finish this workout?")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isResting {
                restTimerSection
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: isResting)
        .onAppear {
            startWorkoutTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(formatTime(elapsedTime))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if let workout = workoutViewModel.activeWorkout {
                    Text("\(workout.exercises.count) EXERCISES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
                .background(Color(white: 0.2))
        }
        .background(Color.black)
    }
    
    private var restTimerSection: some View {
        VStack(spacing: 12) {
            Text("REST TIME")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)

            HStack(spacing: 20) {
                Button(action: { 
                    restTimer = max(0, restTimer - 15)
                    if restTimer == 0 {
                        isResting = false
                    }
                }) {
                    HStack(spacing: 0){
                        Image(systemName: "minus")
                        .font(.system(size: 14))
                        Text("15")
                        .font(.system(size: 18))
                    }
                    
                    .foregroundColor(.neonGreen)
                }

                Text(formatTime(restTimer))
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(restTimer <= 10 ? .red : .white)
                    .monospacedDigit()

                Button(action: { restTimer += 15 }) {
                    HStack(spacing: 0){
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                        Text("15")
                            .font(.system(size: 18))
                    }
                        .foregroundColor(.neonGreen)
                }
            }

            Button(action: {
                isResting = false
                restTimer = 0
            }) {
                Text("Skip Rest")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.neonGreen)
            }
        }
        .padding()
        .padding(.horizontal, 40)// ✅ padding “dentro” del card
        .glassEffect(in: RoundedRectangle(cornerRadius: 15))
        .padding(.bottom, 12) // ✅ poco padding afuera (solo separación)
    }
    
    private func startWorkoutTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            if isResting && restTimer > 0 {
                restTimer -= 1
                if restTimer == 0 {
                    isResting = false
                }
            }
        }
    }
    
    private func startRestTimer() {
        restTimer = 90
        isResting = true
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private func addExerciseToWorkout(_ exercise: Exercise) {
        guard var workout = workoutViewModel.activeWorkout else { return }
        workoutViewModel.addExercise(to: &workout, exercise: exercise, targetSets: 3)
        workoutViewModel.activeWorkout = workout
    }
}

struct ExerciseCard: View {
    let exercise: ActiveWorkoutExercise
    let exerciseIndex: Int
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onSetComplete: () -> Void
    @State private var setInputs: [SetInput] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(exercise.completedSets.count)/\(exercise.targetSets) logged")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        // Remove exercise
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("SET")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 50)
                    
                    Text("REPS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    
                    Text("WEIGHT (KG)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                        .frame(width: 44)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ForEach(0..<setInputs.count, id: \.self) { index in
                    SetRow(
                        setNumber: index + 1,
                        input: binding(for: index),
                        isCompleted: exercise.completedSets.contains(where: { $0.setNumber == index + 1 }),
                        onComplete: {
                            completeSet(at: index)
                        }
                    )
                }
                
                Button(action: { addSet() }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("ADD SET")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.neonGreen)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding()
        .padding(.horizontal)
        .onAppear {
            initializeSetInputs()
        }
    }
    
    private func binding(for index: Int) -> Binding<SetInput> {
        Binding(
            get: {
                if index < setInputs.count {
                    return setInputs[index]
                }
                return SetInput(reps: "", weight: "")
            },
            set: { newValue in
                if index < setInputs.count {
                    setInputs[index] = newValue
                }
            }
        )
    }
    
    private func initializeSetInputs() {
        let count = max(1, exercise.targetSets)
        setInputs = (0..<count).map { _ in SetInput(reps: "-", weight: "") }
    }
    
    private func addSet() {
        setInputs.append(SetInput(reps: "-", weight: ""))
    }
    
    private func completeSet(at index: Int) {
        guard index < setInputs.count else { return }
        
        let setNumber = index + 1
        let isCurrentlyCompleted = exercise.completedSets.contains(where: { $0.setNumber == setNumber })
        
        if isCurrentlyCompleted {
            workoutViewModel.uncompleteSet(exerciseIndex: exerciseIndex, setNumber: setNumber)
        } else {
            let input = setInputs[index]
            if let reps = Int(input.reps), let weight = Double(input.weight) {
                workoutViewModel.completeSet(
                    exerciseIndex: exerciseIndex,
                    setNumber: setNumber,
                    weight: weight,
                    reps: reps
                )
                onSetComplete()
            }
        }
    }
}

struct SetInput {
    var reps: String
    var weight: String
}

struct SetRow: View {
    let setNumber: Int
    @Binding var input: SetInput
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 50)
            
            TextField("15", text: $input.reps)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(8)
            
            TextField("12.00", text: $input.weight)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(8)
            
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? .green : .gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
}
