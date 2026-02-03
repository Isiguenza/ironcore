import SwiftUI

struct RoutineFolder: Identifiable, Codable {
    let id: String
    var name: String
    var routineIds: [String]
    
    init(id: String = UUID().uuidString, name: String, routineIds: [String] = []) {
        self.id = id
        self.name = name
        self.routineIds = routineIds
    }
}

struct ExerciseTab: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showRoutineBuilder = false
    @State private var showActiveWorkout = false
    @State private var folders: [RoutineFolder] = []
    @State private var expandedFolders: Set<String> = []
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    
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
                        Image(systemName: "plus")
                            .foregroundColor(.neonGreen)
                            .font(.system(size: 18))
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
            loadFolders()
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
            HStack {
                Text("MY ROUTINES")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { showCreateFolder = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.badge.plus")
                        Text("New Folder")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.neonGreen)
                }
            }
            
            if workoutViewModel.routines.isEmpty {
                emptyRoutinesView
            } else {
                // Custom folders
                ForEach(folders) { folder in
                    folderSection(folder: folder)
                }
                
                // "Routines" folder for uncategorized
                if !uncategorizedRoutines.isEmpty {
                    uncategorizedFolderSection
                }
            }
        }
        .alert("New Folder", isPresented: $showCreateFolder) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") {
                createFolder()
            }
        } message: {
            Text("Enter a name for the new folder")
        }
    }
    
    private var uncategorizedFolderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    if expandedFolders.contains("uncategorized") {
                        expandedFolders.remove("uncategorized")
                    } else {
                        expandedFolders.insert("uncategorized")
                    }
                }
            }) {
                HStack {
                    Image(systemName: expandedFolders.contains("uncategorized") ? "folder.fill" : "folder")
                        .font(.system(size: 14))
                        .foregroundColor(.neonGreen)
                    
                    Text("Routines")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text("(\(uncategorizedRoutines.count))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: expandedFolders.contains("uncategorized") ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            if expandedFolders.contains("uncategorized") {
                ForEach(uncategorizedRoutines) { routine in
                    RoutineCard(
                        routine: routine,
                        onStart: {
                            workoutViewModel.startWorkout(routine: routine)
                            showActiveWorkout = true
                        },
                        folders: folders,
                        onMoveToFolder: { folderId in
                            moveRoutineToFolder(routineId: routine.id, folderId: folderId)
                        }
                    )
                }
            }
        }
    }
    
    private func folderSection(folder: RoutineFolder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    if expandedFolders.contains(folder.id) {
                        expandedFolders.remove(folder.id)
                    } else {
                        expandedFolders.insert(folder.id)
                    }
                }
            }) {
                HStack {
                    Image(systemName: expandedFolders.contains(folder.id) ? "folder.fill" : "folder")
                        .font(.system(size: 14))
                        .foregroundColor(.neonGreen)
                    
                    Text(folder.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text("(\(routinesInFolder(folder).count))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Spacer()
                    
                    Image(systemName: expandedFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            if expandedFolders.contains(folder.id) {
                ForEach(routinesInFolder(folder)) { routine in
                    RoutineCard(
                        routine: routine,
                        onStart: {
                            workoutViewModel.startWorkout(routine: routine)
                            showActiveWorkout = true
                        },
                        folders: folders.filter { $0.id != folder.id },
                        onMoveToFolder: { folderId in
                            moveRoutineToFolder(routineId: routine.id, folderId: folderId, fromFolderId: folder.id)
                        },
                        onRemoveFromFolder: {
                            removeRoutineFromFolder(routineId: routine.id, folderId: folder.id)
                        }
                    )
                }
            }
        }
    }
    
    private var uncategorizedRoutines: [Routine] {
        let categorizedIds = Set(folders.flatMap { $0.routineIds })
        return workoutViewModel.routines.filter { !categorizedIds.contains($0.id) }
    }
    
    private func routinesInFolder(_ folder: RoutineFolder) -> [Routine] {
        return workoutViewModel.routines.filter { folder.routineIds.contains($0.id) }
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        let folder = RoutineFolder(name: newFolderName)
        folders.append(folder)
        expandedFolders.insert(folder.id)
        saveFolders()
        newFolderName = ""
    }
    
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: "routine_folders")
        }
    }
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: "routine_folders"),
           let decoded = try? JSONDecoder().decode([RoutineFolder].self, from: data) {
            folders = decoded
            // Expand all folders by default
            expandedFolders = Set(folders.map { $0.id })
            expandedFolders.insert("uncategorized") // Also expand Routines folder
        }
    }
    
    private func moveRoutineToFolder(routineId: String, folderId: String, fromFolderId: String? = nil) {
        // Remove from previous folder if needed
        if let fromId = fromFolderId, let index = folders.firstIndex(where: { $0.id == fromId }) {
            folders[index].routineIds.removeAll { $0 == routineId }
        }
        
        // Add to new folder
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            if !folders[index].routineIds.contains(routineId) {
                folders[index].routineIds.append(routineId)
            }
        }
        
        saveFolders()
    }
    
    private func removeRoutineFromFolder(routineId: String, folderId: String) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].routineIds.removeAll { $0 == routineId }
            saveFolders()
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
    var folders: [RoutineFolder] = []
    var onMoveToFolder: ((String) -> Void)?
    var onRemoveFromFolder: (() -> Void)?
    
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
                    .foregroundColor(.neonGreen)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.05)))
        .contextMenu {
            if !folders.isEmpty {
                Menu("Move to Folder") {
                    ForEach(folders) { folder in
                        Button(folder.name) {
                            onMoveToFolder?(folder.id)
                        }
                    }
                }
            }
            
            if let onRemove = onRemoveFromFolder {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from Folder", systemImage: "folder.badge.minus")
                }
            }
        }
    }
}
