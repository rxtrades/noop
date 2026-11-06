#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// WHOOP-inspired Sleep Performance detail (Mobbin 032/030/035).
struct WhoopSleepDetailView: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var router: NavRouter

    @State private var day: DailyMetric?
    @State private var sleepPerf: Double?
    @State private var ringToken = 0

    private var fraction: Double { (sleepPerf ?? 0) / 100 }
    private var band: Int {
        guard let sleepPerf else { return -1 }
        if sleepPerf >= 85 { return 2 }
        if sleepPerf >= 70 { return 1 }
        return 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WhoopDetailHeroRing(
                    fraction: fraction,
                    displayValue: sleepPerf ?? 0,
                    format: { sleepPerf == nil ? "—" : "\(Int($0.rounded()))" },
                    accent: WhoopIOSDesign.sleepBlue,
                    label: "Sleep Performance",
                    valueSuffix: sleepPerf == nil ? nil : "%",
                    legend: WhoopSleepBandLegend(activeBand: band),
                    animationToken: ringToken
                )

                WhoopMetricsBeakCard {
                    WhoopSleepBarRow(
                        icon: "moon.fill",
                        label: "HOURS VS. NEEDED",
                        percent: hoursVsNeeded,
                        band: bandFor(hoursVsNeeded)
                    )
                    sleepDivider
                    WhoopSleepBarRow(
                        icon: "arrow.triangle.2.circlepath",
                        label: "SLEEP CONSISTENCY",
                        percent: consistency,
                        band: bandFor(consistency)
                    )
                    sleepDivider
                    WhoopSleepBarRow(
                        icon: "bed.double.fill",
                        label: "SLEEP EFFICIENCY",
                        percent: efficiency,
                        band: bandFor(efficiency)
                    )
                    sleepDivider
                    WhoopSleepBarRow(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "HIGH SLEEP STRESS",
                        percent: sleepStress,
                        band: sleepStressBand
                    )
                    HStack(spacing: 14) {
                        legendSwatch(WhoopIOSDesign.trendDown, "Poor")
                        legendSwatch(WhoopIOSDesign.textTertiary, "Sufficient")
                        legendSwatch(WhoopIOSDesign.recoveryGreen, "Optimal")
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)

                lastNightSection
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)

                WhoopCoachCard(message: coachMessage) {
                    router.openCoach()
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
            }
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .whoopDetailNav(
            miniFraction: fraction,
            miniAccent: WhoopIOSDesign.sleepBlue,
            miniValue: sleepPerf.map { "\(Int($0.rounded()))%" } ?? "—"
        )
        .task(id: repo.refreshSeq) {
            await load()
            ringToken += 1
        }
    }

    private var lastNightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Night's Sleep")
                    .font(WhoopType.title(20))
                    .foregroundStyle(.white)
                Spacer()
                Button { router.openAlarms() } label: {
                    HStack(spacing: 4) {
                        Text("EDIT")
                            .font(WhoopType.labelCaps(11))
                            .tracking(0.8)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .buttonStyle(.plain)
            }

            WhoopCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("ASLEEP")
                            .font(WhoopType.caption())
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        Spacer()
                        Text(asleepLabel)
                            .font(WhoopType.metric(22))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }

                    WhoopHypnogramView(
                        deepMin: day?.deepMin ?? 0,
                        remMin: day?.remMin ?? 0,
                        lightMin: day?.lightMin ?? 0,
                        awakeMin: awakeMinutes
                    )

                    WhoopEfficiencyBar(efficiency: efficiency ?? 0)
                }
            }
        }
    }

    private var asleepLabel: String {
        guard let mins = day?.totalSleepMin else { return "—" }
        return String(format: "%d:%02d", Int(mins) / 60, Int(mins) % 60)
    }

    private var awakeMinutes: Double {
        // Rough stand-in when we lack time-in-bed: disturbances * 4 min.
        Double((day?.disturbances ?? 0) * 4)
    }

    private var hoursVsNeeded: Double? {
        guard let asleep = day?.totalSleepMin else { return sleepPerf }
        let need = max(asleep + 30, 420)
        return min(100, (asleep / need) * 100)
    }

    private var consistency: Double? {
        // Proxy from recent sleep totals variance when we lack a dedicated metric.
        let recent = repo.days.suffix(7).compactMap(\.totalSleepMin)
        guard recent.count >= 3 else { return sleepPerf.map { max(40, $0 - 15) } }
        let mean = recent.reduce(0, +) / Double(recent.count)
        let varSum = recent.map { pow($0 - mean, 2) }.reduce(0, +) / Double(recent.count)
        let cv = sqrt(varSum) / max(mean, 1)
        return max(0, min(100, (1 - cv) * 100))
    }

    private var efficiency: Double? {
        day?.efficiency.map { $0 <= 1.5 ? $0 * 100 : $0 } ?? sleepPerf.map { min(98, $0 + 8) }
    }

    private var sleepStress: Double? {
        // Soft proxy: disturbances drive stress up; typical demo nights stay Optimal/Sufficient.
        let d = Double(day?.disturbances ?? 0)
        return min(100, d * 3)
    }

    private var sleepStressBand: Int {
        guard let sleepStress else { return -1 }
        if sleepStress <= 15 { return 2 }
        if sleepStress <= 40 { return 1 }
        return 0
    }

    private func bandFor(_ pct: Double?) -> Int {
        guard let pct else { return -1 }
        if pct >= 85 { return 2 }
        if pct >= 70 { return 1 }
        return 0
    }

    private var coachMessage: String {
        if let sleepPerf {
            if sleepPerf >= 85 {
                return String(localized: "Strong sleep performance. Keep the same bedtime window to lock in recovery.")
            }
            if sleepPerf >= 70 {
                return String(localized: "Decent sleep — a slightly earlier wind-down could push Hours vs Needed into Optimal.")
            }
            return String(localized: "Sleep was short of need. Protect tonight's bedtime and cut late strain.")
        }
        return String(localized: "Wear \(WhoopleBranding.displayName) to sleep to unlock Sleep Performance.")
    }

    private var sleepDivider: some View {
        Rectangle()
            .fill(WhoopIOSDesign.cardBorder)
            .frame(height: 0.5)
            .padding(.leading, 44)
    }

    private func legendSwatch(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(color).frame(width: 14, height: 3)
            Text(title)
                .font(WhoopType.caption(10))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
    }

    private func load() async {
        // Demo seed can land after first paint — prefer any day with sleep minutes.
        let key = Repository.localDayKey(Repository.logicalDay(Date()))
        let candidate = repo.today
            ?? repo.days.first(where: { $0.day == key })
            ?? repo.days.last(where: { $0.totalSleepMin != nil })
            ?? repo.days.last
        day = candidate
        if let day {
            sleepPerf = AnalyticsEngine.Rest.composite(daily: day)
        }
    }
}

#endif
