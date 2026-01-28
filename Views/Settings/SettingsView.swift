import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var healthKitViewModel: HealthKitViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ProfileSection()
                        
                        SettingsSection(title: "Health") {
                            SettingsRow(
                                icon: "heart.text.square.fill",
                                title: "HealthKit",
                                subtitle: healthKitViewModel.isAuthorized ? "Connected" : "Not Connected",
                                action: {
                                    Task {
                                        await healthKitViewModel.requestAuthorization()
                                    }
                                }
                            )
                        }
                        
                        SettingsSection(title: "Account") {
                            SettingsRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                subtitle: "Log out of your account",
                                isDestructive: true,
                                action: {
                                    showingLogoutAlert = true
                                }
                            )
                        }
                        
                        VStack(spacing: 8) {
                            Text("IRONCORE")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct ProfileSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var displayName: String {
        authViewModel.userProfile?.displayName ?? authViewModel.currentUserName ?? "Athlete"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.neonGreen)
                .frame(width: 70, height: 70)
                .overlay(
                    Text(displayName.prefix(1))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if let handle = authViewModel.userProfile?.handle {
                    Text("@\(handle)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                } else if let userId = authViewModel.currentUserId {
                    Text("User ID: \(userId.prefix(12))...")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            content
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : .neonGreen)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
}
