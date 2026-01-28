import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutViewModel: WorkoutViewModel
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    let onSelectExercise: (Exercise) -> Void
    
    var filteredExercises: [Exercise] {
        var exercises = workoutViewModel.exercises
        
        if let muscleGroup = selectedMuscleGroup {
            exercises = exercises.filter { $0.muscleGroup == muscleGroup }
        }
        
        if !searchText.isEmpty {
            exercises = exercises.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return exercises
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchBar(text: $searchText)
                        .padding()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedMuscleGroup == nil,
                                action: { selectedMuscleGroup = nil }
                            )
                            
                            ForEach(MuscleGroup.allCases, id: \.self) { group in
                                FilterChip(
                                    title: group.displayName,
                                    isSelected: selectedMuscleGroup == group,
                                    action: { selectedMuscleGroup = group }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseLibraryRow(exercise: exercise) {
                                    onSelectExercise(exercise)
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.neonGreen)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await workoutViewModel.loadExercises()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises", text: $text)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.neonGreen)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.neonGreen : Color(white: 0.1))
                )
        }
    }
}

struct ExerciseLibraryRow: View {
    let exercise: Exercise
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: muscleGroupIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.neonGreen)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(exercise.muscleGroup.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(exercise.equipment.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.neonGreen)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.05))
            )
        }
    }
    
    private var muscleGroupIcon: String {
        switch exercise.muscleGroup {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "dumbbell.fill"
        case .legs: return "figure.run"
        case .core: return "figure.core.training"
        case .glutes: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}
