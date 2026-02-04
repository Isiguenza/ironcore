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
        
        #if !os(watchOS)
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        #else
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        #endif
    }
    
    // MARK: - Send Messages
    
    func sendRoutines(_ routines: [Routine]) {
        guard WCSession.default.isReachable else {
            print("❌ [WATCH] iPhone not reachable")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(routines)
            let message: [String: Any] = ["routines": data]
            
            WCSession.default.sendMessage(message, replyHandler: { response in
                print("✅ [WATCH] Routines sent successfully")
            }, errorHandler: { error in
                print("❌ [WATCH] Failed to send routines: \(error)")
            })
        } catch {
            print("❌ [WATCH] Failed to encode routines: \(error)")
        }
    }
    
    func sendWorkoutStarted(routine: Routine) {
        guard WCSession.default.isReachable else {
            print("❌ [WATCH] iPhone not reachable")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(routine)
            let message: [String: Any] = [
                "action": "workoutStarted",
                "routine": data
            ]
            
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("❌ [WATCH] Failed to send workout started: \(error)")
            })
        } catch {
            print("❌ [WATCH] Failed to encode workout: \(error)")
        }
    }
    
    func sendWorkoutUpdate(_ workout: ActiveWorkoutSync) {
        guard WCSession.default.isReachable else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(workout)
            let message: [String: Any] = [
                "action": "workoutUpdate",
                "workout": data
            ]
            
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("❌ [WATCH] Failed to send workout update: \(error)")
            })
        } catch {
            print("❌ [WATCH] Failed to encode workout update: \(error)")
        }
    }
    
    func sendWorkoutFinished() {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = ["action": "workoutFinished"]
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
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
    
    #if !os(watchOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ [WATCH] Session became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ [WATCH] Session deactivated")
        session.activate()
    }
    #endif
    
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
        
        if let action = message["action"] as? String {
            switch action {
            case "requestRoutines":
                // Notify iPhone to send routines
                NotificationCenter.default.post(name: NSNotification.Name("WatchRequestedRoutines"), object: nil)
                print("✅ [WATCH] Routine request received from Watch")
                break
                
            case "workoutStarted":
                if let routineData = message["routine"] as? Data {
                    do {
                        let decoder = JSONDecoder()
                        let routine = try decoder.decode(Routine.self, from: routineData)
                        workoutStartedFromWatch = true
                        print("✅ [WATCH] Workout started from watch: \(routine.name)")
                    } catch {
                        print("❌ [WATCH] Failed to decode routine: \(error)")
                    }
                }
                
            case "workoutUpdate":
                if let workoutData = message["workout"] as? Data {
                    do {
                        let decoder = JSONDecoder()
                        let workout = try decoder.decode(ActiveWorkoutSync.self, from: workoutData)
                        activeWorkoutFromWatch = workout
                        print("✅ [WATCH] Workout updated from watch")
                    } catch {
                        print("❌ [WATCH] Failed to decode workout: \(error)")
                    }
                }
                
            case "workoutFinished":
                workoutStartedFromWatch = false
                activeWorkoutFromWatch = nil
                print("✅ [WATCH] Workout finished from watch")
                
            default:
                break
            }
        }
        
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
