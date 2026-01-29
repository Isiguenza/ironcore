import SwiftUI

struct ExerciseTab: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showRoutineBuilder = false
    @State private var showActiveWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        quickStartSection
                        routinesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showRoutineBuilder = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.neonGreen)
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showRoutineBuilder) {
                RoutineBuilderView(workoutViewModel: workoutViewModel)
            }
            .fullScreenCover(isPresented: $showActiveWorkout) {
                if workoutViewModel.activeWorkout != nil {
                    ActiveWorkoutView(workoutViewModel: workoutViewModel)
                }
            }
        }
        .onAppear {
            Task {
                await workoutViewModel.loadExercises()
                await workoutViewModel.loadRoutines()
            }
        }
    }
    
    private var quickStartSection: some View {
        Button(action: {
            workoutViewModel.startWorkout()
            showActiveWorkout = true
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black)
                
                Text("Quick Start")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.black.opacity(0.6))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.neonGreen))
        }
    }
    
    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MY ROUTINES")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
            
            if workoutViewModel.routines.isEmpty {
                emptyRoutinesView
            } else {
                ForEach(workoutViewModel.routines) { routine in
                    RoutineCard(routine: routine) {
                        workoutViewModel.startWorkout(routine: routine)
                        showActiveWorkout = true
                    }
                }
            }
        }
    }
    
    private var emptyRoutinesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Routines Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Create your first routine to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: { showRoutineBuilder = true }) {
                Text("Create Routine")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.05)))
    }
}

struct RoutineCard: View {
    let routine: Routine
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(routine.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                if let description = routine.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Label("\(routine.exercises.count) exercises", systemImage: "dumbbell.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onStart) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.05)))
    }
}
