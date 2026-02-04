import SwiftUI

struct ActiveWorkoutView: View {
    let routine: Routine?
    
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    @State private var selectedExerciseIndex = 0
    @State private var showingExerciseDetail = false
    @State private var showingActions = false
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Header section
                
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            
                            VStack(alignment: .leading){
                                
                                Text("Duration")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.white)
                            
                                
                                Text(formatTime(elapsedTime))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .bold()
                                
                            }
                      
                            Spacer()
                            
                            VStack(alignment: .trailing){
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                    Text("\(workoutManager.heartRate)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                    Text("\(workoutManager.calories)kcal")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                
                
            
                    ForEach(Array(workoutManager.activeWorkout?.exercises.enumerated() ?? [].enumerated()), id: \.offset) { index, exercise in
                        Button(action: {
                            selectedExerciseIndex = index
                            showingExerciseDetail = true
                        }) {
                            ExerciseRowView(exercise: exercise)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                
                
                // Action buttons section
                Section {
                    
                    
                    Button("Add Excersice"){
                        workoutManager.finishWorkout()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    
                    Button("Finish Workout"){
                        workoutManager.finishWorkout()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.neonGreen)
                    .foregroundStyle(.black)
                    .listRowBackground(Color.clear)
                    
                    Button("Discard Workout", role: .destructive){
                        showingDiscardAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(workoutManager.activeWorkout?.routineName ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingDiscardAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                // Siempre iniciar el workout cuando se abre la vista
                if let routine = routine {
                    workoutManager.startWorkout(routine: routine)
                    print("🏋️ [WATCH] Starting workout with routine: \(routine.name), exercises: \(routine.exercises.count)")
                } else {
                    workoutManager.startEmptyWorkout()
                    print("🏋️ [WATCH] Starting empty workout (Quick Start)")
                }
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .sheet(isPresented: $showingExerciseDetail) {
                if let workout = workoutManager.activeWorkout {
                    ExerciseDetailView(
                        exercise: workout.exercises[selectedExerciseIndex],
                        exerciseIndex: selectedExerciseIndex
                    )
                }
            }
            .sheet(isPresented: $showingActions) {
                workoutActionsSheet
            }
            .alert("Ready?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    workoutManager.discardWorkout()
                    dismiss()
                }
                Button("Resume", role: .cancel) { }
            } message: {
                Text("Are you sure you want to discard this workout?")
            }
        }
        .overlay {
            if workoutManager.isResting {
                RestTimerOverlay()
            }
        }
    }
    
    
    private var workoutActionsSheet: some View {
        VStack(spacing: 16) {
            Text("Actions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
            
            Button(action: {
                showingActions = false
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
                showingActions = false
                workoutManager.finishWorkout()
                dismiss()
            }) {
                Text("Finish Workout...")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.neonGreen)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            
            Button(action: {
                showingActions = false
                showingDiscardAlert = true
            }) {
                Text("Discard Workout...")
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
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = workoutManager.activeWorkout?.startTime {
                elapsedTime = Int(Date().timeIntervalSince(startTime))
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ActiveWorkoutExercise
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise image circular
            if let gifUrl = exercise.exercise.gifUrl, let url = URL(string: gifUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "dumbbell")
                            .foregroundColor(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(exercise.completedSets.count)/\(exercise.targetSets) sets")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
       
    }
}
