import Foundation
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResult: UserProfile?
    
    private let dataAPI = NeonDataAPIClient.shared
    
    func loadFriends() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        isLoading = true
        
        do {
            let friendships: [Friendship] = try await dataAPI.get(
                table: "friendships",
                query: [
                    "or": "(requester_id.eq.\(userId),addressee_id.eq.\(userId))",
                    "status": "eq.accepted"
                ]
            )
            
            var friendIds: [String] = []
            for friendship in friendships {
                if friendship.requesterId == userId {
                    friendIds.append(friendship.addresseeId)
                } else {
                    friendIds.append(friendship.requesterId)
                }
            }
            
            if !friendIds.isEmpty {
                let profiles: [UserProfile] = try await dataAPI.get(
                    table: "profiles",
                    query: ["user_id": "in.(\(friendIds.joined(separator: ",")))"]
                )
                friends = profiles
            } else {
                friends = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadPendingRequests() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            pendingRequests = try await dataAPI.get(
                table: "friendships",
                query: [
                    "addressee_id": "eq.\(userId)",
                    "status": "eq.pending"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadSentRequests() async {
        guard let userId = KeychainStore.shared.getUserId() else { return }
        
        do {
            sentRequests = try await dataAPI.get(
                table: "friendships",
                query: [
                    "requester_id": "eq.\(userId)",
                    "status": "eq.pending"
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchUserByHandle(_ handle: String) async {
        guard !handle.isEmpty else {
            searchResult = nil
            return
        }
        
        errorMessage = nil
        
        do {
            let profiles: [UserProfile] = try await dataAPI.get(
                table: "profiles",
                query: ["handle": "eq.\(handle)"]
            )
            searchResult = profiles.first
        } catch {
            errorMessage = error.localizedDescription
            searchResult = nil
        }
    }
    
    func sendFriendRequest(to addresseeId: String) async {
        errorMessage = nil
        
        do {
            let request = FriendRequest(
                requesterId: nil,
                addresseeId: addresseeId,
                status: "pending"
            )
            
            let _: [Friendship] = try await dataAPI.post(table: "friendships", body: request)
            await loadSentRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(_ friendship: Friendship) async {
        errorMessage = nil
        
        do {
            let update = FriendshipStatusUpdate(status: "accepted")
            let _: [Friendship] = try await dataAPI.patch(
                table: "friendships",
                body: update,
                query: ["id": "eq.\(friendship.id)"]
            )
            
            await loadPendingRequests()
            await loadFriends()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func rejectFriendRequest(_ friendship: Friendship) async {
        errorMessage = nil
        
        do {
            try await dataAPI.delete(
                table: "friendships",
                query: ["id": "eq.\(friendship.id)"]
            )
            
            await loadPendingRequests()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct FriendshipStatusUpdate: Codable {
    let status: String
}
