import Foundation

struct PerformanceBarData: Equatable, Identifiable {
    let id: String
    let label: String
    let value: Double
    let highlight: Bool
}

struct PerformanceDashboardState: Equatable {
    let tier: TierSnapshot
    let weeklyOnTime: [PerformanceBarData]

    var acceptanceLabel: String {
        Self.percent(tier.acceptanceRate)
    }

    var completionLabel: String {
        Self.percent(min(1, max(0, tier.onTimeRate + 0.03)))
    }

    var ratingLabel: String {
        String(format: "%.2f", tier.ratingAverage)
    }

    var tierProgress: Double {
        guard tier.tier.progressTarget > 0 else { return 1 }
        return min(1, Double(tier.deliveries30D) / Double(tier.tier.progressTarget))
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
