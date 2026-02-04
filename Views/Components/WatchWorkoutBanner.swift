import SwiftUI

struct WatchWorkoutBanner: View {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @Binding var showActiveWorkout: Bool
    
    var body: some View {
        if connectivity.workoutStartedFromWatch {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 20))
                        .foregroundColor(.neonGreen)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout activo en Apple Watch")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let workout = connectivity.activeWorkoutFromWatch {
                            Text(workout.routineName)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showActiveWorkout = true
                    }) {
                        Text("Ver")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.neonGreen)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(white: 0.1))
            }
            .transition(.move(edge: .top))
        }
    }
}
