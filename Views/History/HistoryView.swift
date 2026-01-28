import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyViewModel: HistoryViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("History")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                    
                    if historyViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .neonGreen))
                        Spacer()
                    } else if historyViewModel.weeklyScores.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(historyViewModel.weeklyScores) { score in
                                    HistoryRow(weeklyScore: score)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .refreshable {
                    await historyViewModel.loadHistory()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await historyViewModel.loadHistory()
            }
        }
    }
}

struct HistoryRow: View {
    let weeklyScore: WeeklyScore
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatWeekDate(weeklyScore.weekStart))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formatCreatedDate(weeklyScore.createdAt))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(weeklyScore.score)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.neonGreen)
            }
            
            VStack(spacing: 8) {
                MiniScoreRow(
                    title: "Consistency",
                    score: weeklyScore.components.consistency,
                    maxScore: 40
                )
                MiniScoreRow(
                    title: "Volume",
                    score: weeklyScore.components.volume,
                    maxScore: 25
                )
                MiniScoreRow(
                    title: "Intensity",
                    score: weeklyScore.components.intensity,
                    maxScore: 25
                )
                MiniScoreRow(
                    title: "Recovery",
                    score: weeklyScore.components.recovery,
                    maxScore: 10
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatWeekDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Week of \(formatter.string(from: date))"
    }
    
    private func formatCreatedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "Submitted \(formatter.string(from: date))"
    }
}

struct MiniScoreRow: View {
    let title: String
    let score: Int
    let maxScore: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondaryBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.neonGreen)
                        .frame(width: geometry.size.width * (Double(score) / Double(maxScore)), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(score)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No History Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Submit your first weekly score to see it here")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
