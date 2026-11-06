#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP "My Dashboard" — one card per metric with baseline + trend (Mobbin 079).
struct WhoopDashboardView: View {
    @EnvironmentObject private var repo: Repository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WhoopIOSDesign.cardGap) {
                HStack {
                    Text("My Dashboard")
                        .font(WhoopType.title(20))
                        .foregroundStyle(WhoopIOSDesign.textPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("CUSTOMIZE")
                            .font(WhoopType.labelCaps(11))
                            .tracking(0.8)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .padding(.bottom, 4)

                ForEach(rows) { row in
                    NavigationLink(value: TabRoute.metric(row.key)) {
                        WhoopDashboardMetricRow(
                            icon: row.icon,
                            title: row.title,
                            value: row.value,
                            baseline: row.baseline,
                            trend: row.trend
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: TabRoute.metricExplorer) {
                    WhoopCard {
                        WhoopSectionHeader("Explore all metrics")
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .whoopPageBackground()
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Row: Identifiable {
        let id: String
        let key: String
        let icon: String
        let title: String
        let value: String
        let baseline: String?
        let trend: WhoopTrendDirection
    }

    private var rows: [Row] {
        let today = repo.today ?? repo.days.last
        let hrv = today?.avgHrv
        let hrvBase = repo.chargeBaselines?.hrv.baseline
        let rhr = today?.restingHr
        let rhrBase = repo.chargeBaselines.map { Int($0.restingHR.baseline.rounded()) }

        func trend(current: Double?, baseline: Double?, higherIsBetter: Bool) -> WhoopTrendDirection {
            guard let current, let baseline, baseline > 0 else { return .flat }
            let delta = current - baseline
            if abs(delta / baseline) < 0.03 { return .flat }
            let up = delta > 0
            if higherIsBetter { return up ? .upGood : .downBad }
            return up ? .upBad : .downGood
        }

        return [
            Row(id: "rhr", key: "rhr", icon: "heart.fill", title: "RESTING HEART RATE",
                value: rhr.map { "\($0)" } ?? "—",
                baseline: rhrBase.map { "\($0)" },
                trend: trend(current: rhr.map(Double.init), baseline: rhrBase.map(Double.init), higherIsBetter: false)),
            Row(id: "steps", key: "steps", icon: "figure.walk", title: "STEPS",
                value: today?.steps.map { formatted($0) } ?? "—",
                baseline: "7,500",
                trend: trend(current: today?.steps.map(Double.init), baseline: 7500, higherIsBetter: true)),
            Row(id: "hrv", key: "hrv", icon: "waveform.path.ecg", title: "HEART RATE VARIABILITY",
                value: hrv.map { String(format: "%.0f", $0) } ?? "—",
                baseline: hrvBase.map { String(format: "%.0f", $0) },
                trend: trend(current: hrv, baseline: hrvBase, higherIsBetter: true)),
            Row(id: "kcal", key: "energy_kcal", icon: "flame.fill", title: "CALORIES",
                value: today?.activeKcalEst.map { formatted(Int($0.rounded())) } ?? "—",
                baseline: "1,600",
                trend: trend(current: today?.activeKcalEst, baseline: 1600, higherIsBetter: true)),
            Row(id: "recovery", key: "recovery", icon: "heart.circle", title: "RECOVERY",
                value: today?.recovery.map { "\(Int($0.rounded()))%" } ?? "—",
                baseline: nil,
                trend: .flat),
            Row(id: "strain", key: "strain", icon: "flame", title: "STRAIN",
                value: today?.strain.map { String(format: "%.1f", $0) } ?? "—",
                baseline: nil,
                trend: .flat),
            Row(id: "sleep", key: "sleep_total_min", icon: "moon.zzz", title: "ASLEEP TIME",
                value: today?.totalSleepMin.map { formatSleep($0) } ?? "—",
                baseline: nil,
                trend: .flat),
        ]
    }

    private func formatted(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func formatSleep(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return String(format: "%d:%02d", h, m)
    }
}

#endif
