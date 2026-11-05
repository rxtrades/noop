#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Whoople home — Mobbin WHOOP layout: black canvas, animated rings, monitor cards.
struct WhoopHomeView: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var router: NavRouter
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal

    @AppStorage(UnitPrefs.effortScaleKey) private var effortScaleRaw = EffortScale.whoop.rawValue

    @State private var selectedDayOffset = 0
    @State private var displayDay: DailyMetric?
    @State private var restScore: Double?
    @State private var vitalsDay: DailyMetric?
    @State private var showSettings = false
    @State private var cardsVisible = false
    @State private var ringAnimationToken = 0

    private var effortScale: EffortScale { UnitPrefs.resolveEffortScale(effortScaleRaw) }
    private var effortGaugeMax: Double { effortScale == .whoop ? 21 : 100 }

    private var selectedDayKey: String {
        let base = Repository.logicalDay(Date())
        let day = Calendar.current.date(byAdding: .day, value: -selectedDayOffset, to: base) ?? base
        return Repository.localDayKey(day)
    }

    private var dayHeaderLabel: String {
        if selectedDayOffset == 0 { return String(localized: "Today") }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let day = Calendar.current.date(byAdding: .day, value: -selectedDayOffset, to: Repository.logicalDay(Date())) ?? Date()
        return f.string(from: day).uppercased()
    }

    private var wearStreak: Int {
        var streak = 0
        let sorted = repo.days.sorted { $0.day > $1.day }
        for d in sorted {
            guard d.recovery != nil else { break }
            streak += 1
        }
        return streak
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: 1).id(Self.topAnchorID)
                    WhoopHomeHeader(
                        dayLabel: dayHeaderLabel,
                        streakDays: wearStreak,
                        onPreviousDay: { selectedDayOffset = min(selectedDayOffset + 1, maxDayOffset) },
                        onNextDay: selectedDayOffset > 0,
                        onNextDayTap: { selectedDayOffset = max(0, selectedDayOffset - 1) },
                        batteryPct: model.live.batteryPct.map { Int($0.rounded()) },
                        connected: model.live.connected,
                        onProfileTap: { showSettings = true },
                        onDeviceTap: { router.openDevices() }
                    )
                    .whoopCardAppear(index: 0, visible: cardsVisible)

                    metricRingsRow
                        .whoopCardAppear(index: 1, visible: cardsVisible)

                    insightCard
                        .whoopCardAppear(index: 2, visible: cardsVisible)

                    HStack(alignment: .top, spacing: 10) {
                        healthMonitorCard
                        stressMonitorCard
                    }
                    .whoopCardAppear(index: 3, visible: cardsVisible)

                    if selectedDayOffset == 0, displayDay?.recovery == nil {
                        calibrationCard
                            .whoopCardAppear(index: 4, visible: cardsVisible)
                    }

                    NavigationLink { WhoopDashboardView() } label: {
                        WhoopCard { WhoopSectionHeader("My Dashboard") }
                    }
                    .buttonStyle(.plain)
                    .whoopCardAppear(index: 5, visible: cardsVisible)

                    NavigationLink(value: TabRoute.dataSources) {
                        WhoopCard { WhoopSectionHeader("Data Sources") }
                    }
                    .buttonStyle(.plain)
                    .whoopCardAppear(index: 6, visible: cardsVisible)
                }
                .padding(.horizontal, NoopMetrics.screenHPadding)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .background(WhoopIOSDesign.background.ignoresSafeArea())
            .refreshable {
                await repo.refresh()
                ringAnimationToken += 1
            }
            .task(id: "\(repo.refreshSeq)-\(selectedDayOffset)") {
                await load()
                ringAnimationToken += 1
                if !cardsVisible {
                    withAnimation(WhoopIOSDesign.cardAppear) { cardsVisible = true }
                }
            }
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo(Self.topAnchorID, anchor: .top) }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .background(WhoopIOSDesign.background.ignoresSafeArea())
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showSettings = false }
                                    .foregroundStyle(StrandPalette.accent)
                            }
                        }
                }
            }
        }
    }

    private static let topAnchorID = "whoopHomeTop"

    private var maxDayOffset: Int { min(30, max(0, repo.days.count - 1)) }

    private var metricRingsRow: some View {
        HStack(alignment: .top, spacing: 4) {
            NavigationLink { sleepDestination } label: { sleepRingColumn }.buttonStyle(.plain)
            NavigationLink { recoveryDestination } label: { recoveryRingColumn }.buttonStyle(.plain)
            NavigationLink { strainDestination } label: { strainRingColumn }.buttonStyle(.plain)
        }
    }

    private var sleepRingColumn: some View {
        let perf = restScore ?? displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
        let has = perf != nil
        return WhoopAnimatedMetricRingColumn(
            label: "Sleep",
            fraction: has ? (perf! / 100) : 0,
            displayValue: perf ?? 0,
            format: { has ? "\(Int($0.rounded()))" : "—" },
            accent: WhoopIOSDesign.sleepBlue,
            useStrainGradient: false,
            animationToken: ringAnimationToken
        )
    }

    private var recoveryRingColumn: some View {
        let rec = displayDay?.recovery
        let has = rec != nil
        return WhoopAnimatedMetricRingColumn(
            label: "Recovery",
            fraction: has ? (rec! / 100) : 0,
            displayValue: rec ?? 0,
            format: { has ? "\(Int($0.rounded()))" : "—" },
            accent: WhoopIOSDesign.recoveryAccent(score: rec),
            useStrainGradient: false,
            animationToken: ringAnimationToken
        )
    }

    private var strainRingColumn: some View {
        let strain = displayDay?.strain
        let has = strain != nil
        let max = effortGaugeMax
        return WhoopAnimatedMetricRingColumn(
            label: "Strain",
            fraction: has ? (strain! / max) : 0,
            displayValue: strain ?? 0,
            format: { has ? UnitFormatter.effortDisplay($0, scale: effortScale) : "—" },
            accent: WhoopIOSDesign.strainBlue,
            useStrainGradient: has,
            animationToken: ringAnimationToken
        )
    }

    private var insightCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(insightTitle)
                    .font(StrandFont.headline)
                    .foregroundStyle(.white)
                Text(insightBody)
                    .font(StrandFont.subhead)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var insightTitle: String {
        if let rec = displayDay?.recovery {
            if rec >= 67 { return String(localized: "Strong recovery") }
            if rec >= 34 { return String(localized: "Moderate recovery") }
            return String(localized: "Recovery needs rest")
        }
        return String(localized: "Building your baseline")
    }

    private var insightBody: String {
        if displayDay?.recovery != nil {
            return String(localized: "Your body is ready to train within today's strain budget. Tap Recovery for HRV, RHR, and sleep performance.")
        }
        return String(localized: "Wear \(WhoopleBranding.displayName) to sleep for a few nights to unlock recovery, strain, and sleep scores.")
    }

    private var healthMonitorCard: some View {
        NavigationLink(value: TabRoute.health) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 8) {
                    WhoopSectionHeader("Health Monitor", showsChevron: true)
                    Text("WITHIN RANGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                    Text("Vitals & trends")
                        .font(StrandFont.caption)
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var stressMonitorCard: some View {
        NavigationLink(value: TabRoute.stress) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 8) {
                    WhoopSectionHeader("Stress Monitor", showsChevron: true)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("MEDIUM")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                        Text("—")
                            .font(StrandFont.title2)
                            .foregroundStyle(.white)
                    }
                    Text("Open for today's curve")
                        .font(StrandFont.caption)
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var sleepDestination: some View { SleepView() }

    private var recoveryDestination: some View {
        WhoopRecoveryDetailView(
            recovery: displayDay?.recovery,
            hrv: displayDay?.avgHrv ?? vitalsDay?.avgHrv,
            rhr: displayDay?.restingHr ?? vitalsDay?.restingHr,
            respRate: displayDay?.respRateBpm ?? vitalsDay?.respRateBpm,
            sleepPerf: restScore ?? displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) },
            hrvBaseline: repo.chargeBaselines?.hrv.baseline,
            rhrBaseline: repo.chargeBaselines.map { Int($0.restingHR.baseline.rounded()) },
            respBaseline: repo.chargeBaselines?.resp.baseline,
            sleepBaseline: nil
        )
    }

    private var strainDestination: some View {
        WhoopStrainDetailView(
            strain: displayDay?.strain,
            steps: displayDay?.steps,
            hrZoneMinutes: nil,
            strengthMinutes: nil,
            outOf: effortGaugeMax
        )
    }

    private var calibrationCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Calibration")
                    .font(StrandFont.headline)
                    .foregroundStyle(.white)
                Text("Wear \(WhoopleBranding.displayName) to sleep for a few nights to calibrate recovery, strain, and sleep scores.")
                    .font(StrandFont.subhead)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                PipBar(value: Double(min(4, repo.days.filter { $0.recovery != nil }.count)),
                       range: 0...4, segments: 4, tint: WhoopIOSDesign.strainBlue, height: 8)
            }
        }
    }

    private func load() async {
        displayDay = repo.days.first(where: { $0.day == selectedDayKey }) ?? (selectedDayOffset == 0 ? repo.today : nil)
        vitalsDay = selectedDayOffset == 0
            ? Repository.lastVitalsDay(days: repo.days, todayKey: selectedDayKey)
            : nil
        restScore = displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
    }
}

#endif
