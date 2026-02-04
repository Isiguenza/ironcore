import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var searchHandle = ""
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Friends")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSearch.toggle()
                        }) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 20))
                                .foregroundColor(.neonGreen)
                                .frame(width: 44, height: 44)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if !friendsViewModel.pendingRequests.isEmpty {
                                PendingRequestsSection()
                            }
                            
                            if !friendsViewModel.friends.isEmpty {
                                FriendsListSection()
                            } else if friendsViewModel.pendingRequests.isEmpty {
                                EmptyFriendsView()
                            }
                        }
                        .padding()
                    }
                }
                .refreshable {
                    await friendsViewModel.loadFriends()
                    await friendsViewModel.loadPendingRequests()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSearch) {
                SearchFriendsView()
            }
        }
        .onAppear {
            Task {
                await friendsViewModel.loadFriends()
                await friendsViewModel.loadPendingRequests()
            }
        }
    }
}

struct PendingRequestsSection: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Requests")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(friendsViewModel.pendingRequests) { request in
                PendingRequestRow(friendship: request)
            }
        }
    }
}

struct PendingRequestRow: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    let friendship: Friendship
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.neonGreen)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend Request")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("From: \(friendship.requesterId)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    Task {
                        await friendsViewModel.acceptFriendRequest(friendship)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Color.neonGreen)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    Task {
                        await friendsViewModel.rejectFriendRequest(friendship)
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct FriendsListSection: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Friends")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(friendsViewModel.friends) { friend in
                FriendRow(friend: friend)
            }
        }
    }
}

struct FriendRow: View {
    let friend: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.neonGreen)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.displayName.prefix(1))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("@\(friend.handle)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct SearchFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var searchHandle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    CustomTextField(
                        placeholder: "Search by handle",
                        text: $searchHandle,
                        icon: "magnifyingglass"
                    )
                    .padding()
                    .onChange(of: searchHandle) { newValue in
                        Task {
                            await friendsViewModel.searchUserByHandle(newValue)
                        }
                    }
                    
                    if let user = friendsViewModel.searchResult {
                        SearchResultRow(user: user)
                    } else if !searchHandle.isEmpty {
                        Text("No user found")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.neonGreen)
                }
            }
        }
    }
}

struct SearchResultRow: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    let user: UserProfile
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.neonGreen)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.displayName.prefix(1))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("@\(user.handle)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if requestSent {
                Text("Sent")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else {
                Button(action: {
                    Task {
                        await friendsViewModel.sendFriendRequest(to: user.userId)
                        requestSent = true
                    }
                }) {
                    Text("Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.neonGreen)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Tap the + button to search and add friends")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
