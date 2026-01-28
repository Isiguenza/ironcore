import Foundation
import Combine
import HealthKit

@MainActor
class HealthKitViewModel: ObservableObject {
    @Published var isAuthorized = false {
        didSet {
            UserDefaults.standard.set(isAuthorized, forKey: "healthkit_authorized")
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let healthKitManager = HealthKitManager.shared
    
    init() {
        // Restore HealthKit authorization state
        isAuthorized = UserDefaults.standard.bool(forKey: "healthkit_authorized")
        
        // Check actual authorization status
        if healthKitManager.isHealthDataAvailable {
            let status = HKHealthStore().authorizationStatus(for: .workoutType())
            if status == .sharingAuthorized {
                isAuthorized = true
            }
        }
    }
    
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await healthKitManager.requestAuthorization()
            
            // Wait a moment for authorization to process
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check actual authorization status
            checkAuthorizationStatus()
            
            // Mark as authorized regardless to allow user to continue
            // They can grant permissions later from Settings
            isAuthorized = true
            
        } catch {
            errorMessage = error.localizedDescription
            // Still allow to continue even if there's an error
            isAuthorized = true
        }
        
        isLoading = false
    }
    
    func checkAuthorizationStatus() {
        if healthKitManager.isHealthDataAvailable {
            let status = HKHealthStore().authorizationStatus(for: .workoutType())
            print("🏥 [HEALTHKIT] Current authorization status: \(status.rawValue)")
            isAuthorized = status == .sharingAuthorized
            
            if isAuthorized {
                print("✅ [HEALTHKIT] Permissions granted!")
            } else {
                print("❌ [HEALTHKIT] Permissions NOT granted (status: \(status.rawValue))")
            }
        }
    }
}
