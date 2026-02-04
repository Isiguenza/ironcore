import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Leaderboard")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    
                    if leaderboardViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .neonGreen))
                        Spacer()
                    } else if leaderboardViewModel.leaderboard.isEmpty {
                        EmptyLeaderboardView()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Array(leaderboardViewModel.leaderboard.enumerated()), id: \.element.id) { index, friendWithScore in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        friendWithScore: friendWithScore,
                                        isCurrentUser: friendWithScore.id == authViewModel.currentUserId
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
                .refreshable {
                    await friendsViewModel.loadFriends()
                    await leaderboardViewModel.loadWeeklyLeaderboard(friends: friendsViewModel.friends)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await friendsViewModel.loadFriends()
                await leaderboardViewModel.loadWeeklyLeaderboard(friends: friendsViewModel.friends)
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let friendWithScore: FriendWithScore
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friendWithScore.profile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let rating = friendWithScore.rating {
                    HStack(spacing: 4) {
                        Text(rating.rank.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if let division = rating.division {
                            Text("• Div \(division)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            Text("\(friendWithScore.displayScore)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.neonGreen)
        }
        .padding()
        .background(isCurrentUser ? Color.neonGreen.opacity(0.1) : Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentUser ? Color.neonGreen : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .neonYellow
        case 2: return .gray.opacity(0.7)
        case 3: return .orange
        default: return .cardBackground
        }
    }
}

struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Leaderboard Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Add friends to see the weekly leaderboard")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
