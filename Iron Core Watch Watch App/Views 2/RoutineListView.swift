import SwiftUI

struct RoutineListView: View {
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if workoutManager.routines.isEmpty {
                    emptyState
                } else {
                    List {
                        // Quick Start NavigationLink
                        NavigationLink(destination: ActiveWorkoutView(routine: nil)) {
                            QuickStartCardView()
                        }
                        .listRowInsets(EdgeInsets())
                        
                        // Routine NavigationLinks
                        ForEach(workoutManager.routines) { routine in
                            NavigationLink(destination: ActiveWorkoutView(routine: routine)) {
                                RoutineCardView(routine: routine)
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle("Rutinas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItemGroup(placement: .topBarLeading){
                    
                        
                            // Solo mostrar sync cuando hay rutinas
                            if !workoutManager.routines.isEmpty {
                                Button{
                                    workoutManager.syncRoutines()
                                } label: {
                                    
                                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                                        .foregroundStyle(Color.neonGreen)
                                        
                                }
                                

                            }
                        
                   
                }
            }
            .onAppear {
                workoutManager.syncRoutines()
            }
            .onReceive(connectivity.$receivedMessage) { message in
                if let message = message, let routinesData = message["routines"] as? Data {
                    workoutManager.loadRoutines(from: routinesData)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No hay rutinas")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Sincroniza desde tu iPhone")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            syncButton
        }
        .padding()
    }
    
    private var syncButton: some View {
        Button(action: {
            workoutManager.syncRoutines()
        }) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16))
                Text("Sincronizar rutinas")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.neonGreen)
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct RoutineCardView: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if let description = routine.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 10))
                Text("\(routine.exercises.count) ejercicios")
                    .font(.system(size: 12))
            }
            
        }
        .padding(.vertical, 8)
    }
}

struct QuickStartCardView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.black)

            Text("Quick Start")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.neonGreen)
        )
    }
}
