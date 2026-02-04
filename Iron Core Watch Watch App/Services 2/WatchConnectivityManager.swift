import Foundation
import Combine
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var receivedMessage: [String: Any]?
    @Published var workoutStartedFromWatch = false
    @Published var activeWorkoutFromWatch: ActiveWorkoutSync?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Messages
    
    func requestRoutines() {
        guard WCSession.default.isReachable else {
            print("❌ [WATCH] iPhone not reachable")
            return
        }
        
        let message: [String: Any] = ["action": "requestRoutines"]
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("✅ [WATCH] Request sent, response: \(response)")
        }, errorHandler: { error in
            print("❌ [WATCH] Failed to request routines: \(error)")
        })
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("❌ [WATCH] Activation failed: \(error)")
            } else {
                print("✅ [WATCH] Session activated: \(activationState.rawValue)")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("🔄 [WATCH] Reachability changed: \(session.isReachable)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            handleReceivedMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        print("📩 [WATCH] Received message: \(message.keys)")
        
        if let routinesData = message["routines"] as? Data {
            receivedMessage = message
            print("✅ [WATCH] Routines data received")
        }
    }
}

// MARK: - Sync Models

struct ActiveWorkoutSync: Codable {
    let routineName: String
    let startTime: Date
    let elapsedTime: Int
    let exercises: [ExerciseSync]
    let currentExerciseIndex: Int
}

struct ExerciseSync: Codable {
    let name: String
    let gifUrl: String?
    let completedSets: Int
    let totalSets: Int
    let sets: [SetSync]
}

struct SetSync: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let completed: Bool
}
