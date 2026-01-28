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
    @State private var showEditWorkoutTime = false
    @State private var showCustomWorkoutTime = false
    @State private var customWorkoutTimeInput = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
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
            .safeAreaInset(edge: .bottom) {
            if isResting {
                restTimerSection
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: isResting)
        .sheet(isPresented: $showEditWorkoutTime) {
            WorkoutTimePicker(elapsedTime: $elapsedTime, showCustom: $showCustomWorkoutTime)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
            .alert("Custom Workout Time", isPresented: $showCustomWorkoutTime) {
                TextField("Seconds", text: $customWorkoutTimeInput)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { }
                Button("Set") {
                    if let seconds = Int(customWorkoutTimeInput), seconds >= 0 {
                        elapsedTime = seconds
                    }
                }
            } message: {
                Text("Enter custom workout time in seconds")
            }
            .onAppear {
                startWorkoutTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Button(action: { showEditWorkoutTime = true }) {
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ExerciseCard: View {
    let exercise: ActiveWorkoutExercise
    let exerciseIndex: Int
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onSetComplete: () -> Void
    @State private var setInputs: [SetInput] = []
    @State private var weightUnit: WeightUnit = .lbs
    @State private var showUnitPicker = false
    
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
                    
                    Button(action: { showUnitPicker = true }) {
                        Text("WEIGHT (\(weightUnit.rawValue))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                    }
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
        .sheet(isPresented: $showUnitPicker) {
            WeightUnitPicker(selectedUnit: $weightUnit)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
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
        setInputs = (0..<count).map { _ in SetInput(reps: "", weight: "") }
    }
    
    private func addSet() {
        setInputs.append(SetInput(reps: "", weight: ""))
    }
    
    private func completeSet(at index: Int) {
        guard index < setInputs.count else { return }
        
        let setNumber = index + 1
        let isCurrentlyCompleted = exercise.completedSets.contains(where: { $0.setNumber == setNumber })
        
        if isCurrentlyCompleted {
            workoutViewModel.uncompleteSet(exerciseIndex: exerciseIndex, setNumber: setNumber)
        } else {
            let input = setInputs[index]
            let reps = Int(input.reps) ?? 0
            let weight = Double(input.weight) ?? 0.0
            
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
            
            TextField("-", text: $input.reps)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.1))
                .cornerRadius(8)
            
            TextField("-", text: $input.weight)
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

enum WeightUnit: String {
    case lbs = "LBS"
    case kg = "KG"
}

struct WeightUnitPicker: View {
    @Binding var selectedUnit: WeightUnit
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Weight Unit")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding()
            
            Divider()
            
            VStack(spacing: 0) {
                Button(action: {
                    selectedUnit = .lbs
                    dismiss()
                }) {
                    HStack {
                        Text("LBS")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Spacer()
                        if selectedUnit == .lbs {
                            Image(systemName: "checkmark")
                                .foregroundColor(.neonGreen)
                        }
                    }
                    .padding()
                    .background(Color(white: 0.1))
                }
                
                Divider()
                
                Button(action: {
                    selectedUnit = .kg
                    dismiss()
                }) {
                    HStack {
                        Text("KG")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Spacer()
                        if selectedUnit == .kg {
                            Image(systemName: "checkmark")
                                .foregroundColor(.neonGreen)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct WorkoutTimePicker: View {
    @Binding var elapsedTime: Int
    @Binding var showCustom: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedSeconds = 0
    
    let timeOptions: [Int] = {
        var options: [Int] = []
        // 15 segundos hasta 4 horas (240 minutos = 14,400 segundos)
        // Incrementos de 15 segundos
        for seconds in stride(from: 15, through: 240, by: 15) {
            options.append(seconds)
        }
        // Después de 4 minutos (240s), incrementos de 30 segundos hasta 10 minutos
        for seconds in stride(from: 270, through: 600, by: 30) {
            options.append(seconds)
        }
        // Después de 10 minutos, incrementos de 1 minuto hasta 30 minutos
        for minutes in stride(from: 11, through: 30, by: 1) {
            options.append(minutes * 60)
        }
        // Después de 30 minutos, incrementos de 15 minutos hasta 4 horas
        for minutes in stride(from: 45, through: 240, by: 15) {
            options.append(minutes * 60)
        }
        return options
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top)
            
            Button(action: {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCustom = true
                }
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Custom Time")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.neonGreen))
            }
            .padding(.horizontal)
            
            Divider()
            
            Picker("Time", selection: $selectedSeconds) {
                ForEach(timeOptions, id: \.self) { seconds in
                    Text(formatTimeOption(seconds))
                        .tag(seconds)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 150)
            
            Button(action: {
                elapsedTime = selectedSeconds
                dismiss()
            }) {
                Text("Set Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.2)))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        
        .onAppear {
            selectedSeconds = elapsedTime
        }
    }
    
    private func formatTimeOption(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins) min"
            } else {
                return "\(mins)m \(secs)s"
            }
        } else {
            let hours = seconds / 3600
            let mins = (seconds % 3600) / 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}
