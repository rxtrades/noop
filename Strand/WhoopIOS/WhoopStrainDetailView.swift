#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-inspired strain detail: blue hero ring + zone/steps rows with baselines + Coach card.
struct WhoopStrainDetailView: View {
    var strain: Double?
    var steps: Int?
    var hrZoneMinutes: Int?
    var strengthMinutes: Int?
    var outOf: Double? = nil
    var zone13BaselineMin: Int? = 21
    var zone45BaselineMin: Int? = 5
    var strengthBaselineMin: Int? = 13
    var stepsBaseline: Int? = 7689

    @EnvironmentObject private var router: NavRouter
    @AppStorage(UnitPrefs.effortScaleKey) private var effortScaleRaw = EffortScale.whoop.rawValue
    @State private var ringToken = 0

    private var effortScale: EffortScale { UnitPrefs.resolveEffortScale(effortScaleRaw) }
    private var gaugeMax: Double { effortScale == .whoop ? 21 : 100 }

    private var value: Double { strain ?? 0 }
    private var scaleMax: Double { outOf ?? gaugeMax }
    private var fraction: Double {
        guard scaleMax > 0 else { return 0 }
        return min(max(value / scaleMax, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WhoopDetailHeroRing(
                    fraction: fraction,
                    displayValue: value,
                    format: { strain == nil ? "—" : UnitFormatter.effortDisplay($0, scale: effortScale) },
                    accent: WhoopIOSDesign.strainBlue,
                    label: "Strain",
                    showsStartTick: strain != nil,
                    animationToken: ringToken
                )

                WhoopMetricsBeakCard {
                    WhoopMetricTrendRow(
                        icon: "heart.text.square",
                        label: "Heart Rate Zones 1–3",
                        value: hrZoneMinutes.map { formatDuration($0) } ?? "0:00",
                        current: hrZoneMinutes.map(Double.init),
                        baseline: zone13BaselineMin.map(Double.init),
                        higherIsBetter: true
                    )
                    strainDivider
                    WhoopMetricTrendRow(
                        icon: "heart.fill",
                        label: "Heart Rate Zones 4–5",
                        value: "0:00",
                        current: 0,
                        baseline: zone45BaselineMin.map(Double.init),
                        higherIsBetter: true
                    )
                    strainDivider
                    WhoopMetricTrendRow(
                        icon: "dumbbell.fill",
                        label: "Strength Activity Time",
                        value: strengthMinutes.map { formatDuration($0) } ?? "0:00",
                        current: strengthMinutes.map(Double.init),
                        baseline: strengthBaselineMin.map(Double.init),
                        higherIsBetter: true
                    )
                    strainDivider
                    WhoopMetricTrendRow(
                        icon: "figure.walk",
                        label: "Steps",
                        value: steps.map { formatSteps($0) } ?? "—",
                        current: steps.map(Double.init),
                        baseline: stepsBaseline.map(Double.init),
                        higherIsBetter: true
                    )
                    WhoopVsBaselineLegend()
                        .padding(.bottom, 10)
                }
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
            miniAccent: WhoopIOSDesign.strainBlue,
            miniValue: strain.map { UnitFormatter.effortDisplay($0, scale: effortScale) } ?? "—"
        )
        .task { ringToken += 1 }
    }

    private var coachMessage: String {
        if strain != nil {
            if fraction < 0.45 {
                return String(localized: "You've made solid progress on your Strain today. A moderate activity could bring you closer to your optimal Strain range.")
            }
            if fraction < 0.75 {
                return String(localized: "Strain is building nicely. Keep fueling and leave room for recovery tonight.")
            }
            return String(localized: "High strain day — prioritize wind-down and sleep to lock in the adaptation.")
        }
        return String(localized: "Start an activity to begin accumulating Strain for today.")
    }

    private var strainDivider: some View {
        Rectangle()
            .fill(WhoopIOSDesign.cardBorder)
            .frame(height: 0.5)
            .padding(.leading, 44)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%d:%02d", h, m)
    }

    private func formatSteps(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

#endif
