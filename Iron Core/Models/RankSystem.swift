import SwiftUI

struct RankTier: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let color: Color
    let glowColor: Color
    let minLP: Int
    let maxLP: Int
    let description: String
    let concept: String
    
    var iconName: String {
        return name.lowercased()
    }
}

class RankSystem {
    static let shared = RankSystem()
    
    let ranks: [RankTier] = [
        RankTier(
            name: "UNTRAINED",
            displayName: "Untrained",
            color: Color(red: 0.4, green: 0.3, blue: 0.2),
            glowColor: Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.3),
            minLP: 0,
            maxLP: 499,
            description: "The beginning of your journey",
            concept: "Raw potential"
        ),
        RankTier(
            name: "CONDITIONED",
            displayName: "Conditioned",
            color: Color(red: 0.6, green: 0.9, blue: 0.3),
            glowColor: Color(red: 0.6, green: 0.9, blue: 0.3).opacity(0.4),
            minLP: 500,
            maxLP: 999,
            description: "Consistent training shows results",
            concept: "Activation"
        ),
        RankTier(
            name: "STRONG",
            displayName: "Strong",
            color: Color(red: 0.3, green: 0.6, blue: 0.9),
            glowColor: Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.4),
            minLP: 1000,
            maxLP: 1499,
            description: "Building real strength",
            concept: "Structure"
        ),
        RankTier(
            name: "ATHLETIC",
            displayName: "Athletic",
            color: Color(red: 0.95, green: 0.85, blue: 0.2),
            glowColor: Color(red: 0.95, green: 0.85, blue: 0.2).opacity(0.5),
            minLP: 1500,
            maxLP: 1999,
            description: "Peak performance achieved",
            concept: "Performance"
        ),
        RankTier(
            name: "ELITE",
            displayName: "Elite",
            color: Color(red: 0.95, green: 0.5, blue: 0.2),
            glowColor: Color(red: 0.95, green: 0.5, blue: 0.2).opacity(0.5),
            minLP: 2000,
            maxLP: 2499,
            description: "Among the best",
            concept: "Respect"
        ),
        RankTier(
            name: "FORGED",
            displayName: "Forged",
            color: Color(red: 0.9, green: 0.2, blue: 0.2),
            glowColor: Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.6),
            minLP: 2500,
            maxLP: 9999,
            description: "Absolute discipline mastered",
            concept: "Legendary"
        )
    ]
    
    func getRank(for lp: Int) -> RankTier {
        return ranks.first { lp >= $0.minLP && lp <= $0.maxLP } ?? ranks[0]
    }
    
    func getNextRank(for lp: Int) -> RankTier? {
        let currentRank = getRank(for: lp)
        guard let currentIndex = ranks.firstIndex(where: { $0.name == currentRank.name }) else { return nil }
        let nextIndex = currentIndex + 1
        return nextIndex < ranks.count ? ranks[nextIndex] : nil
    }
    
    func getProgress(for lp: Int) -> Double {
        let rank = getRank(for: lp)
        let lpInRank = lp - rank.minLP
        let lpRange = rank.maxLP - rank.minLP + 1
        return Double(lpInRank) / Double(lpRange)
    }
}
