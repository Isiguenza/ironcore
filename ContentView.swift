import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var healthKitViewModel: HealthKitViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if healthKitViewModel.isAuthorized {
                    MainTabView()
                } else {
                    HealthKitOnboardingView()
                }
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            authViewModel.checkAuthState()
        }
    }
}
