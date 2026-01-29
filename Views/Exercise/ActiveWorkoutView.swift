import SwiftUI
import UIKit

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var restTimer = 0
    @State private var isResting = false
    @State private var showExerciseLibrary = false
    @State private var showExerciseSearch = false
    @State private var showFinishConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var showEditWorkoutTime = false
    @State private var showCustomWorkoutTime = false
    @State private var customWorkoutTimeInput = ""
    @State private var isReorganizing = false
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                List {
                        if let workout = workoutViewModel.activeWorkout {
                            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    exerciseIndex: index,
                                    workoutViewModel: workoutViewModel,
                                    isReorganizing: $isReorganizing,
                                    onSetComplete: { 
                                        if exercise.restSeconds > 0 {
                                            startRestTimer(duration: exercise.restSeconds)
                                        }
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onMove { source, destination in
                                workoutViewModel.reorderExercises(from: source, to: destination)
                            }
                        }
                        
                        Section {
                            Button(action: { showExerciseSearch = true }) {
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
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            
                            Button(action: { showDiscardConfirmation = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                    Text("Discard Workout")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.15)))
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            .sheet(isPresented: $showExerciseSearch) {
                ExerciseSearchView { selectedExercise in
                    Task {
                        if let exerciseId = await workoutViewModel.addExerciseFromAPI(selectedExercise),
                           let exercise = workoutViewModel.exercises.first(where: { $0.id == exerciseId }) {
                            if var workout = workoutViewModel.activeWorkout {
                                workoutViewModel.addExercise(to: &workout, exercise: exercise)
                                workoutViewModel.activeWorkout = workout
                            }
                        }
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isReorganizing {
                        Button(action: {
                            withAnimation {
                                isReorganizing = false
                            }
                        }) {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.neonGreen)
                        }
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
            .alert("Discard Workout", isPresented: $showDiscardConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    workoutViewModel.activeWorkout = nil
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to discard this workout? All progress will be lost.")
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
            .environment(\.editMode, isReorganizing ? .constant(.active) : .constant(.inactive))
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
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
            
            // Progress bar
            if let workout = workoutViewModel.activeWorkout {
                let progress = calculateWorkoutProgress(workout: workout)
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 4)
                    
                    // Progress fill
                    Rectangle()
                        .fill(Color.neonGreen)
                        .frame(width: UIScreen.main.bounds.width * progress, height: 4)
                }
                .frame(height: 4)
            }
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
    
    private func startRestTimer(duration: Int = 90) {
        restTimer = duration
        isResting = true
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func calculateWorkoutProgress(workout: ActiveWorkout) -> Double {
        guard !workout.exercises.isEmpty else { return 0 }
        
        let totalSetsTarget = workout.exercises.reduce(0) { $0 + $1.targetSets }
        let completedSetsCount = workout.exercises.reduce(0) { $0 + $1.completedSets.count }
        
        guard totalSetsTarget > 0 else { return 0 }
        
        return Double(completedSetsCount) / Double(totalSetsTarget)
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
    @Binding var isReorganizing: Bool
    let onSetComplete: () -> Void
    @State private var setInputs: [SetInput] = []
    @State private var weightUnit: WeightUnit = .lbs
    @State private var showUnitPicker = false
    @State private var showRestTimePicker = false
    @State private var showExerciseDetail = false
    @State private var isKeyboardVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                if let gifUrl = exercise.gifUrl, let url = URL(string: gifUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(white: 0.15))
                                    .frame(width: 50, height: 50)
                                
                                if case .failure = phase {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                } else {
                                    ProgressView()
                                        .tint(.neonGreen)
                                }
                            }
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: { showExerciseDetail = true }) {
                        Text(exercise.exerciseName)
                            .font(.system(size: 14, weight: .bold))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(exercise.completedSets.count)/\(exercise.targetSets) logged")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    Button(action: { showRestTimePicker = true }) {
                        Text(exercise.restSeconds == 0 ? "Rest: OFF" : "Rest: \(formatRestTime(exercise.restSeconds))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.neonGreen)
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding(.horizontal)
                
               
                
                if !isReorganizing {
                    Menu {
                        Button {
                            withAnimation {
                                isReorganizing = true
                            }
                        } label: {
                            Label("Reorganize", systemImage: "arrow.up.arrow.down")
                        }
                        
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
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("SET")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 40)
                    
                    Text("LAST")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 60)
                    
                    Text("REPS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: { showUnitPicker = true }) {
                        Text("WEIGHT (\(weightUnit.rawValue))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                        .frame(width: 44)
                }
                
                
                
                
                .padding(.vertical, 8)
                
                ForEach(0..<setInputs.count, id: \.self) { index in
                    SetRow(
                        setNumber: index + 1,
                        input: binding(for: index),
                        isCompleted: exercise.completedSets.contains(where: { $0.setNumber == index + 1 }),
                        onComplete: {
                            completeSet(at: index)
                        },
                        lastWeight: "-",
                        isKeyboardVisible: $isKeyboardVisible
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
        .overlay {
            if isKeyboardVisible {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .allowsHitTesting(true)
            }
        }
        .sheet(isPresented: $showUnitPicker) {
            WeightUnitPicker(selectedUnit: $weightUnit)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRestTimePicker) {
            RestTimePicker(restSeconds: Binding(
                get: { exercise.restSeconds },
                set: { newValue in
                    if var workout = workoutViewModel.activeWorkout {
                        workout.exercises[exerciseIndex].restSeconds = newValue
                        workoutViewModel.activeWorkout = workout
                    }
                }
            ))
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showExerciseDetail) {
            ExerciseDetailView(
                exerciseName: exercise.exerciseName,
                exerciseId: exercise.exerciseId,
                gifUrl: exercise.gifUrl
            )
        }
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
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins) min"
            } else {
                return "\(mins)m \(secs)s"
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isKeyboardVisible = false
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
    let lastWeight: String
    @Binding var isKeyboardVisible: Bool
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 40)
            
            Text(lastWeight)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 60)
                .onTapGesture(count: 2) {
                    if lastWeight != "-" {
                        input.weight = lastWeight
                    }
                }
            
            TextFieldWithDone(text: $input.reps, placeholder: "-", keyboardType: .numberPad) {
                isKeyboardVisible = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(8)
            .simultaneousGesture(TapGesture().onEnded {
                isKeyboardVisible = true
            })
            
            TextFieldWithDone(text: $input.weight, placeholder: "-", keyboardType: .decimalPad) {
                isKeyboardVisible = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(8)
            .simultaneousGesture(TapGesture().onEnded {
                isKeyboardVisible = true
            })
            
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
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
    @State private var selectedMinutes = 0
    
    let timeOptions: [Int] = {
        var options: [Int] = [-1] // -1 = Custom
        // 1 a 30 minutos, incrementos de 1
        for minutes in stride(from: 1, through: 30, by: 1) {
            options.append(minutes)
        }
        // 35 a 60 minutos, incrementos de 5
        for minutes in stride(from: 35, through: 60, by: 5) {
            options.append(minutes)
        }
        // 75 a 240 minutos (4 horas), incrementos de 15
        for minutes in stride(from: 75, through: 240, by: 15) {
            options.append(minutes)
        }
        return options
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 24)
            
            Picker("Time", selection: $selectedMinutes) {
                ForEach(timeOptions, id: \.self) { minutes in
                    Text(formatTimeOption(minutes))
                        .tag(minutes)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 180)
            .onChange(of: selectedMinutes) { newValue in
                if newValue == -1 {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCustom = true
                    }
                }
            }
            
            Button(action: {
                if selectedMinutes > 0 {
                    elapsedTime = selectedMinutes * 60
                }
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
            selectedMinutes = elapsedTime / 60
        }
    }
    
    private func formatTimeOption(_ minutes: Int) -> String {
        if minutes == -1 {
            return "Custom"
        } else if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

struct TextFieldWithDone: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    var onDone: () -> Void
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .white
        textField.delegate = context.coordinator
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.donePressed))
        doneButton.tintColor = UIColor(red: 0.6, green: 1.0, blue: 0.2, alpha: 1.0)
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onDone: onDone)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onDone: () -> Void
        
        init(text: Binding<String>, onDone: @escaping () -> Void) {
            _text = text
            self.onDone = onDone
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        @objc func donePressed() {
            onDone()
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onDone()
            return true
        }
    }
}

struct RestTimePicker: View {
    @Binding var restSeconds: Int
    @Environment(\.dismiss) var dismiss
    @State private var selectedSeconds = 0
    
    let timeOptions: [Int] = {
        var options: [Int] = [0] // 0 = OFF
        // 30s a 3 minutos, incrementos de 15s
        for seconds in stride(from: 30, through: 180, by: 15) {
            options.append(seconds)
        }
        // 3.5 a 5 minutos, incrementos de 30s
        for seconds in stride(from: 210, through: 300, by: 30) {
            options.append(seconds)
        }
        return options
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rest Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 24)
            
            Picker("Rest", selection: $selectedSeconds) {
                ForEach(timeOptions, id: \.self) { seconds in
                    Text(formatRestOption(seconds))
                        .tag(seconds)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 180)
            
            Button(action: {
                restSeconds = selectedSeconds
                dismiss()
            }) {
                Text("Set Rest Time")
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
            selectedSeconds = restSeconds
        }
    }
    
    private func formatRestOption(_ seconds: Int) -> String {
        if seconds == 0 {
            return "OFF"
        } else if seconds < 60 {
            return "\(seconds)s"
        } else {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins) min"
            } else {
                return "\(mins)m \(secs)s"
            }
        }
    }
}
