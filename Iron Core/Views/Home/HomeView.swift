import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var rankingViewModel: RankingViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HeaderSection()
                        
                        if let score = rankingViewModel.currentWeekScore {
                            ScoreBreakdownCard(components: score)
                        } else {
                            CalculateScoreCard()
                        }
                        
                        if let rating = rankingViewModel.currentRating {
                            RankDisplayCard(lp: rating.lp)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await rankingViewModel.loadCurrentRating()
                    await rankingViewModel.calculateCurrentWeekScore()
                    
                    if rankingViewModel.currentWeekScore != nil {
                        await rankingViewModel.submitWeeklyScore()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await authViewModel.loadUserProfile()
                await rankingViewModel.loadCurrentRating()
                await rankingViewModel.calculateCurrentWeekScore()
                
                if rankingViewModel.currentWeekScore != nil {
                    await rankingViewModel.submitWeeklyScore()
                }
            }
        }
    }
}

struct HeaderSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Text(authViewModel.userProfile?.displayName ?? authViewModel.currentUserName ?? "Athlete")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.neonGreen)
                .frame(width: 50, height: 50)
                .overlay(
                    Text((authViewModel.userProfile?.displayName ?? authViewModel.currentUserName ?? "A").prefix(1))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                )
        }
    }
}

struct ScoreBreakdownCard: View {
    let components: ScoreComponents
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.neonGreen)
                Text("This Week's Score")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(components.total)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.neonGreen)
            }
            
            VStack(spacing: 12) {
                ScoreRow(
                    title: "Consistency",
                    score: components.consistency,
                    maxScore: 40,
                    color: .neonGreen
                )
                ScoreRow(
                    title: "Volume",
                    score: components.volume,
                    maxScore: 25,
                    color: .neonYellow
                )
                ScoreRow(
                    title: "Intensity",
                    score: components.intensity,
                    maxScore: 25,
                    color: .neonOrange
                )
                ScoreRow(
                    title: "Recovery",
                    score: components.recovery,
                    maxScore: 10,
                    color: .neonCyan
                )
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

struct ScoreRow: View {
    let title: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(score)/\(maxScore)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (Double(score) / Double(maxScore)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct CalculateScoreCard: View {
    @EnvironmentObject var rankingViewModel: RankingViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.neonGreen)
            
            Text("Calculate Your Score")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Tap below to analyze this week's workouts and calculate your fitness score")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await rankingViewModel.calculateCurrentWeekScore()
                }
            }) {
                if rankingViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("Calculate Score")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.neonGreen)
            .cornerRadius(12)
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondaryBackground)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.neonGreen)
                    .frame(width: geometry.size.width * value, height: 8)
            }
        }
        .frame(height: 8)
    }
}
