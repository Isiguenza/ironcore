import SwiftUI

struct RankDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentLP: Int
    @State private var showExplainer = false
    
    var currentRank: RankTier {
        RankSystem.shared.getRank(for: currentLP)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        CurrentRankSection(currentLP: currentLP, currentRank: currentRank)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ALL RANKS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 24)
                            
                            ForEach(RankSystem.shared.ranks) { rank in
                                RankTierRow(
                                    rank: rank,
                                    isCurrentRank: rank.name == currentRank.name,
                                    isUnlocked: currentLP >= rank.minLP
                                )
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Rank System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showExplainer = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.system(size: 22))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .sheet(isPresented: $showExplainer) {
                RankExplainerSheet()
            }
        }
    }
}

struct CurrentRankSection: View {
    let currentLP: Int
    let currentRank: RankTier
    
    var progress: Double {
        RankSystem.shared.getProgress(for: currentLP)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(currentRank.glowColor)
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 150, height: 150)
                
                if let image = UIImage(named: currentRank.iconName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                } else {
                    Image(systemName: "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(currentRank.color)
                }
            }
            
            VStack(spacing: 8) {
                Text(currentRank.displayName.uppercased())
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(currentRank.color)
                
                Text(currentRank.concept)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text("\(currentLP) LP")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 4)
            }
            
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondaryBackground)
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [currentRank.color.opacity(0.7), currentRank.color]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(currentRank.minLP) LP")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(currentRank.maxLP) LP")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct RankTierRow: View {
    let rank: RankTier
    let isCurrentRank: Bool
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isCurrentRank ? rank.glowColor : Color.clear)
                    .frame(width: 70, height: 70)
                    .blur(radius: isCurrentRank ? 15 : 0)
                
                Circle()
                    .fill(Color.secondaryBackground)
                    .frame(width: 60, height: 60)
                
                if let image = UIImage(named: rank.iconName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .opacity(isUnlocked ? 1.0 : 0.3)
                } else {
                    Image(systemName: "shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isUnlocked ? rank.color : .gray)
                        .opacity(isUnlocked ? 1.0 : 0.3)
                }
                
                if isCurrentRank {
                    Circle()
                        .stroke(rank.color, lineWidth: 3)
                        .frame(width: 60, height: 60)
                }


            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(rank.displayName.uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isUnlocked ? rank.color : .gray)
                    
                    if isCurrentRank {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(rank.color)
                            .cornerRadius(4)
                    }
                }
                
                Text(rank.concept)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text("\(rank.minLP) - \(rank.maxLP) LP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(isCurrentRank ? Color.cardBackground : Color.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}
