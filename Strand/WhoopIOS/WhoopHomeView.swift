#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// WHOOP-inspired Today / Home: true-black canvas, three metric rings, dark cards.
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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    Color.clear.frame(height: 1).id(Self.topAnchorID)
                    WhoopHomeHeader(
                        dayLabel: dayHeaderLabel,
                        onPreviousDay: { selectedDayOffset = min(selectedDayOffset + 1, maxDayOffset) },
                        onNextDay: selectedDayOffset > 0,
                        onNextDayTap: { selectedDayOffset = max(0, selectedDayOffset - 1) },
                        batteryPct: model.live.batteryPct.map { Int($0.rounded()) },
                        connected: model.live.connected,
                        onProfileTap: { showSettings = true },
                        onDeviceTap: { router.openDevices() }
                    )
                    metricRingsRow
                    if selectedDayOffset == 0, displayDay?.recovery == nil {
                        calibrationCard
                    }
                    NavigationLink(value: TabRoute.stress) {
                        WhoopCard {
                            VStack(alignment: .leading, spacing: 8) {
                                WhoopSectionHeader("Stress Monitor")
                                Text("Tap to open stress trends and calibration.")
                                    .font(StrandFont.subhead)
                                    .foregroundStyle(StrandPalette.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: TabRoute.metric("recovery")) {
                        WhoopCard {
                            VStack(alignment: .leading, spacing: 8) {
                                WhoopSectionHeader("Strain & Recovery")
                                Text("Weekly trends and correlations.")
                                    .font(StrandFont.subhead)
                                    .foregroundStyle(StrandPalette.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    NavigationLink { WhoopDashboardView() } label: {
                        WhoopCard {
                            WhoopSectionHeader("My Dashboard")
                        }
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: TabRoute.dataSources) {
                        WhoopCard {
                            WhoopSectionHeader("Data Sources", showsChevron: true)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, NoopMetrics.screenHPadding)
                .padding(.top, 8)
                .padding(.bottom, NoopMetrics.tabBarClearance + 16)
            }
            .background(StrandPalette.surfaceBase.ignoresSafeArea())
            .refreshable { await repo.refresh() }
            .task(id: "\(repo.refreshSeq)-\(selectedDayOffset)") { await load() }
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo(Self.topAnchorID, anchor: .top) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .background(StrandPalette.surfaceBase.ignoresSafeArea())
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

    private var maxDayOffset: Int {
        min(30, max(0, repo.days.count - 1))
    }

    private var metricRingsRow: some View {
        HStack(alignment: .top, spacing: 8) {
            NavigationLink {
                sleepDestination
            } label: {
                sleepRingColumn
            }
            .buttonStyle(.plain)
            NavigationLink {
                recoveryDestination
            } label: {
                recoveryRingColumn
            }
            .buttonStyle(.plain)
            NavigationLink {
                strainDestination
            } label: {
                strainRingColumn
            }
            .buttonStyle(.plain)
        }
    }

    private var sleepRingColumn: some View {
        let perf = restScore ?? displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
        let frac = perf.map { $0 / 100 } ?? 0
        return WhoopMetricRingColumn(
            label: "Sleep",
            fraction: frac,
            displayValue: perf ?? 0,
            format: { perf != nil ? "\(Int($0.rounded()))" : "—" },
            accent: WhoopIOSColors.sleepAccent
        )
    }

    private var recoveryRingColumn: some View {
        let rec = displayDay?.recovery
        let frac = (rec ?? 0) / 100
        return WhoopMetricRingColumn(
            label: "Recovery",
            fraction: rec != nil ? frac : 0,
            displayValue: rec ?? 0,
            format: { rec != nil ? "\(Int($0.rounded()))" : "—" },
            accent: rec.map { StrandPalette.recoveryColor($0) } ?? StrandPalette.textTertiary
        )
    }

    private var strainRingColumn: some View {
        let strain = displayDay?.strain
        let max = effortGaugeMax
        let frac = strain.map { $0 / max } ?? 0
        return WhoopMetricRingColumn(
            label: "Strain",
            fraction: strain != nil ? frac : 0,
            displayValue: strain ?? 0,
            format: { strain != nil ? UnitFormatter.effortDisplay($0, scale: effortScale) : "—" },
            accent: StrandPalette.effortColor
        )
    }

    @ViewBuilder private var sleepDestination: some View {
        SleepView()
    }

    private var recoveryDestination: some View {
        WhoopRecoveryDetailView(
            recovery: displayDay?.recovery,
            hrv: displayDay?.avgHrv ?? vitalsDay?.avgHrv,
            rhr: displayDay?.restingHr ?? vitalsDay?.restingHr,
            respRate: displayDay?.respRateBpm ?? vitalsDay?.respRateBpm,
            sleepPerf: restScore ?? displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) },
            hrvBaseline: repo.chargeBaselines?.hrv.baseline,
            rhrBaseline: repo.chargeBaselines.map { Int($0.restingHR.baseline.rounded()) },
            respBaseline: nil,
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
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("Wear NOOP to sleep for a few nights to calibrate recovery, strain, and sleep scores.")
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textSecondary)
                PipBar(value: Double(min(4, repo.days.filter { $0.recovery != nil }.count)),
                       range: 0...4, segments: 4, tint: StrandPalette.accent, height: 8)
            }
        }
    }

    private func load() async {
        displayDay = repo.days.first(where: { $0.day == selectedDayKey }) ?? (selectedDayOffset == 0 ? repo.today : nil)
        if selectedDayOffset == 0 {
            vitalsDay = Repository.lastVitalsDay(days: repo.days, todayKey: selectedDayKey)
        } else {
            vitalsDay = nil
        }
        if let day = displayDay {
            restScore = AnalyticsEngine.Rest.composite(daily: day)
        } else {
            restScore = nil
        }
    }
}

#endif
