import SwiftUI

struct HealthKitOnboardingView: View {
    @EnvironmentObject var healthKitViewModel: HealthKitViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.neonGreen)
                    
                    VStack(spacing: 12) {
                        Text("Connect HealthKit")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("IRONCORE needs access to your health data to calculate your fitness score")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    PermissionRow(icon: "figure.run", title: "Workouts", description: "Track your training sessions")
                    PermissionRow(icon: "flame.fill", title: "Active Energy", description: "Measure workout intensity")
                    PermissionRow(icon: "bed.double.fill", title: "Sleep", description: "Monitor recovery")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                if let errorMessage = healthKitViewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await healthKitViewModel.requestAuthorization()
                        }
                    }) {
                        if healthKitViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Connect HealthKit")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.neonGreen)
                    .cornerRadius(16)
                    .disabled(healthKitViewModel.isLoading)
                    
                    Button(action: {
                        healthKitViewModel.isAuthorized = true
                    }) {
                        Text("Skip for Now")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.neonGreen)
                .frame(width: 40, height: 40)
                .background(Color.cardBackground)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
