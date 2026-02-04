import SwiftUI

struct RankDisplayCard: View {
    let lp: Int
    @State private var showRankDetail = false
    
    var currentRank: RankTier {
        RankSystem.shared.getRank(for: lp)
    }
    
    var nextRank: RankTier? {
        RankSystem.shared.getNextRank(for: lp)
    }
    
    var lpToNext: Int {
        guard let next = nextRank else { return 0 }
        return next.minLP - lp
    }
    
    var body: some View {
        Button(action: {
            showRankDetail = true
        }) {
            VStack(spacing: 20) {
                HStack {
                    Text("YOUR RANK")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                ZStack {
                    Circle()
                        .fill(currentRank.glowColor)
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                    
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 120, height: 120)
                    
                    if let image = UIImage(named: currentRank.iconName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                    } else {
                        Image(systemName: "shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(currentRank.color)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(currentRank.displayName.uppercased())
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(currentRank.color)
                    
                    Text(currentRank.concept)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                if let next = nextRank {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            if let nextImage = UIImage(named: next.iconName) {
                                Image(uiImage: nextImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Text("\(lpToNext) LP")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.neonGreen)
                            
                            Text("to \(next.displayName)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.secondaryBackground)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(Color.cardBackground)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showRankDetail) {
            RankDetailSheet(currentLP: lp)
        }
    }
}
