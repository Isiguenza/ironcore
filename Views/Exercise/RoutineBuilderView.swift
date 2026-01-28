import SwiftUI

struct RoutineBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var routineName = ""
    @State private var routineDescription = ""
    @State private var exercises: [RoutineExerciseBuilder] = []
    @State private var showExerciseLibrary = false
    @State private var selectedExercise: Exercise?
    @State private var showAddExercise = false
    @State private var editingExerciseIndex: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Routine Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("e.g. Push Day", text: $routineName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                                .foregroundColor(.white)
                            
                            Text("Description (Optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("e.g. Chest, Shoulders, Triceps", text: $routineDescription)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("EXERCISES")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(exercises.count)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            if exercises.isEmpty {
                                Button(action: { showExerciseLibrary = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Add Exercise")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.neonGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.05)))
                                }
                            } else {
                                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                                    RoutineExerciseRow(
                                        exercise: exercise,
                                        index: index + 1,
                                        onDelete: { exercises.remove(at: index) },
                                        onEdit: {
                                            selectedExercise = exercise.exercise
                                            editingExerciseIndex = index
                                            showAddExercise = true
                                        }
                                    )
                                }
                                
                                Button(action: { showExerciseLibrary = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Exercise")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.neonGreen)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await createRoutineWithExercises()
                            }
                        }) {
                            Text("Create Routine")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.neonGreen))
                        }
                        .disabled(routineName.isEmpty)
                        .opacity(routineName.isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibraryView(workoutViewModel: workoutViewModel) { exercise in
                    selectedExercise = exercise
                    showExerciseLibrary = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddExercise = true
                    }
                }
            }
            .sheet(isPresented: $showAddExercise, onDismiss: {
                selectedExercise = nil
                editingExerciseIndex = nil
            }) {
                if let exercise = selectedExercise {
                    if let editIndex = editingExerciseIndex {
                        AddExerciseToRoutineView(
                            exercise: exercise,
                            initialSets: exercises[editIndex].targetSets,
                            initialReps: exercises[editIndex].targetReps,
                            initialRest: exercises[editIndex].restSeconds,
                            initialNotes: exercises[editIndex].notes
                        ) { sets, reps, rest, notes in
                            exercises[editIndex] = RoutineExerciseBuilder(
                                exercise: exercise,
                                targetSets: sets,
                                targetReps: reps,
                                restSeconds: rest,
                                notes: notes
                            )
                        }
                    } else {
                        AddExerciseToRoutineView(exercise: exercise) { sets, reps, rest, notes in
                            exercises.append(RoutineExerciseBuilder(
                                exercise: exercise,
                                targetSets: sets,
                                targetReps: reps,
                                restSeconds: rest,
                                notes: notes
                            ))
                        }
                    }
                }
            }
        }
    }
    
    private func createRoutineWithExercises() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            let routineRequest = RoutineRequest(
                userId: userId,
                name: routineName,
                description: routineDescription.isEmpty ? nil : routineDescription
            )
            
            let newRoutines: [Routine] = try await workoutViewModel.dataAPI.post(
                table: "routines",
                body: routineRequest
            )
            
            guard let routine = newRoutines.first else { return }
            
            for (index, exercise) in exercises.enumerated() {
                let routineExerciseRequest = RoutineExerciseRequest(
                    routineId: routine.id,
                    exerciseId: exercise.exercise.id,
                    exerciseName: exercise.exercise.name,
                    exerciseOrder: index,
                    targetSets: exercise.targetSets,
                    targetReps: exercise.targetReps,
                    targetWeight: nil,
                    restSeconds: exercise.restSeconds,
                    notes: exercise.notes
                )
                
                let _: [RoutineExercise] = try await workoutViewModel.dataAPI.post(
                    table: "routine_exercises",
                    body: routineExerciseRequest
                )
            }
            
            await workoutViewModel.loadRoutines()
            dismiss()
            
        } catch {
            print("❌ Failed to create routine with exercises: \(error)")
        }
    }
}

struct RoutineExerciseBuilder {
    let exercise: Exercise
    let targetSets: Int
    let targetReps: String
    let restSeconds: Int
    let notes: String?
}

struct RoutineExerciseRow: View {
    let exercise: RoutineExerciseBuilder
    let index: Int
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(exercise.targetSets) sets")
                    Text("•")
                    Text("\(exercise.targetReps) reps")
                    Text("•")
                    Text("\(exercise.restSeconds)s rest")
                }
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Menu {
                Button(action: onEdit) {
                    Label("Editar", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.05)))
    }
}
