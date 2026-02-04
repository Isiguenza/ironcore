import SwiftUI

struct RankExplainerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TabView(selection: $selectedTab) {
                        howItWorksSection.tag(0)
                        scoringSystemSection.tag(1)
                        rankProgressionSection.tag(2)
                        exampleSection.tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
        }
    }
    
    private var howItWorksSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionTitle("How It Works")
                
                infoCard(
                    icon: "calendar",
                    title: "Weekly Scoring",
                    description: "Your workouts and recovery are automatically tracked and scored from 0-100 points every week."
                )
                
                infoCard(
                    icon: "arrow.up.right",
                    title: "Earn LP",
                    description: "Your score is compared to expected performance. Beat it to gain League Points!"
                )
                
                infoCard(
                    icon: "trophy.fill",
                    title: "Climb Ranks",
                    description: "Accumulate LP to progress through 6 ranks, from Untrained to Forged."
                )
            }
            .padding(24)
        }
    }
    
    private var scoringSystemSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionTitle("Score Breakdown")
                
                VStack(spacing: 0) {
                    scoreRow(title: "Consistency", points: 25, icon: "calendar")
                    Divider().background(Color(white: 0.15))
                    
                    scoreRow(title: "Volume", points: 25, icon: "figure.run")
                    Divider().background(Color(white: 0.15))
                    
                    scoreRow(title: "Intensity", points: 25, icon: "flame.fill")
                    Divider().background(Color(white: 0.15))
                    
                    scoreRow(title: "Recovery", points: 25, icon: "bed.double.fill")
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.08))
                )
                
                HStack {
                    Text("Total Score")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("100 pts")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.05))
                )
            }
            .padding(24)
        }
    }
    
    private var rankProgressionSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionTitle("All Ranks")
                
                VStack(spacing: 12) {
                    ForEach(RankSystem.shared.ranks) { tier in
                        rankCard(tier: tier)
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var exampleSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionTitle("Example Calculation")
                
                VStack(spacing: 12) {
                    calcRow(label: "Your Score", value: "75")
                    calcRow(label: "Expected Score", value: "50")
                    
                    Divider()
                        .background(Color(white: 0.2))
                        .padding(.vertical, 4)
                    
                    calcRow(label: "Difference", value: "+25")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.08))
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LP Gained")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("+37 LP")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.05))
                )
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Tip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Train 4-5 days per week with good recovery to steadily gain LP")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.05))
                )
            }
            .padding(24)
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
    }
    
    private func infoCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.cyan)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.05))
        )
    }
    
    private func scoreRow(title: String, points: Int, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(points)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func rankCard(tier: RankTier) -> some View {
        HStack(spacing: 16) {
            if let image = UIImage(named: tier.iconName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            } else {
                Image(systemName: "shield.fill")
                    .font(.system(size: 30))
                    .foregroundColor(tier.color)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tier.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(tier.minLP)-\(tier.maxLP == Int.max ? "∞" : "\(tier.maxLP)") LP")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.05))
        )
    }
    
    private func calcRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    RankExplainerSheet()
}
