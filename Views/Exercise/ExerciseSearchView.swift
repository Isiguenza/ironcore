import SwiftUI
import Combine

struct ExerciseSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ExerciseSearchViewModel()
    @State private var searchText = ""
    let onExerciseSelected: (ExerciseDBItem) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                
                if viewModel.isLoading && viewModel.exercises.isEmpty {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    exerciseList
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Exercise")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.neonGreen)
                }
            }
        }
        .task {
            await viewModel.loadExercises()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search exercises...", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(10)
        .padding()
    }
    
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    ExerciseSearchCard(exercise: exercise) {
                        onExerciseSelected(exercise)
                        dismiss()
                    }
                }
                
                if viewModel.hasMorePages {
                    loadMoreButton
                }
            }
            .padding()
        }
    }
    
    private var loadMoreButton: some View {
        Button(action: {
            Task {
                await viewModel.loadMoreExercises()
            }
        }) {
            HStack {
                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(.neonGreen)
                } else {
                    Text("Load More")
                        .foregroundColor(.neonGreen)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.neonGreen)
            Text("Loading exercises...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(error)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.loadExercises()
                }
            }
            .foregroundColor(.neonGreen)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredExercises: [ExerciseDBItem] {
        if searchText.isEmpty {
            return viewModel.exercises
        }
        return viewModel.exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            exercise.targetMuscles.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
            exercise.bodyParts.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct ExerciseSearchCard: View {
    let exercise: ExerciseDBItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: exercise.gifUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.15))
                                .frame(width: 60, height: 60)
                            
                            if case .failure = phase {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            } else {
                                ProgressView()
                                    .tint(.neonGreen)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if !exercise.targetMuscles.isEmpty {
                            Label(exercise.targetMuscles[0].capitalized, systemImage: "figure.arms.open")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        if !exercise.equipments.isEmpty {
                            Label(exercise.equipments[0].capitalized, systemImage: "dumbbell")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.neonGreen)
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(12)
        }
    }
}

@MainActor
class ExerciseSearchViewModel: ObservableObject {
    @Published var exercises: [ExerciseDBItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalPages = 1
    
    private let apiClient = ExerciseDBAPIClient.shared
    private let pageSize = 20
    
    // Static cache to avoid rate limits
    private static var cachedExercises: [ExerciseDBItem] = []
    private static var cacheTimestamp: Date?
    private static let cacheValidDuration: TimeInterval = 300 // 5 minutes
    
    var hasMorePages: Bool {
        currentPage < totalPages
    }
    
    func loadExercises() async {
        // Check cache first
        if let cacheTime = Self.cacheTimestamp,
           Date().timeIntervalSince(cacheTime) < Self.cacheValidDuration,
           !Self.cachedExercises.isEmpty {
            exercises = Self.cachedExercises
            print("💾 [ExerciseSearch] Loaded \(exercises.count) exercises from cache")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.getExercises(offset: 0, limit: pageSize)
            exercises = response.data
            totalPages = response.metadata.totalPages
            currentPage = response.metadata.currentPage
            
            // Update cache
            Self.cachedExercises = response.data
            Self.cacheTimestamp = Date()
            
            print("📚 [ExerciseSearch] Loaded \(exercises.count) exercises from API")
        } catch {
            print("❌ [ExerciseSearch] Failed to load: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreExercises() async {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        
        do {
            let offset = currentPage * pageSize
            let response = try await apiClient.getExercises(offset: offset, limit: pageSize)
            exercises.append(contentsOf: response.data)
            currentPage = response.metadata.currentPage
            print("📚 [ExerciseSearch] Loaded more exercises, total: \(exercises.count)")
        } catch {
            print("❌ [ExerciseSearch] Failed to load more: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoadingMore = false
    }
}
