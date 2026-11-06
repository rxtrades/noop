#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Whoople home — Mobbin WHOOP layout: rings → insight → monitors → My Day → My Dashboard → charts.
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
    @State private var todayWorkouts: [WorkoutRow] = []
    @State private var showSettings = false
    @State private var cardsVisible = false
    @State private var ringAnimationToken = 0
    @State private var insightIndex = 0
    @State private var scrollMinY: CGFloat = 0
    @State private var showCompactHeader = false

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

    private var insightCards: [(title: String, body: String)] {
        var cards: [(String, String)] = []
        if let rec = displayDay?.recovery {
            if rec >= 67 {
                cards.append((String(localized: "Strong recovery"),
                              String(localized: "Your body is primed. Push into today's strain budget while keeping an eye on HRV and sleep.")))
            } else if rec >= 34 {
                cards.append((String(localized: "Moderate recovery"),
                              String(localized: "Your body is ready to train within today's strain budget. Tap Recovery for HRV, RHR, and sleep performance.")))
            } else {
                cards.append((String(localized: "Recovery needs rest"),
                              String(localized: "Prioritize sleep and keep strain light. Open Recovery for the drivers behind today's score.")))
            }
        } else {
            cards.append((String(localized: "Building your baseline"),
                          String(localized: "Wear \(WhoopleBranding.displayName) to sleep for a few nights to unlock recovery, strain, and sleep scores.")))
        }
        if let hrv = displayDay?.avgHrv ?? vitalsDay?.avgHrv,
           let base = repo.chargeBaselines?.hrv.baseline, base > 0 {
            let pct = Int((((hrv - base) / base) * 100).rounded())
            if abs(pct) >= 10 {
                let title = pct > 0 ? String(localized: "Elevated HRV") : String(localized: "Lower HRV")
                let body = pct > 0
                    ? String(localized: "Your HRV is \(abs(pct))% higher than usual, which signals strong recovery readiness.")
                    : String(localized: "Your HRV is \(abs(pct))% lower than usual. Ease into the day and protect sleep tonight.")
                cards.append((title, body))
            }
        }
        if let sleep = restScore ?? displayDay.flatMap({ AnalyticsEngine.Rest.composite(daily: $0) }), sleep >= 80 {
            cards.append((String(localized: "Solid sleep performance"),
                          String(localized: "Last night's sleep performance hit \(Int(sleep.rounded()))%. Keep the same bedtime window tonight.")))
        }
        return cards
    }

    private var stressLevel: Double {
        // 0…3 WHOOP-style stress. Soft heuristic from recovery + strain when live curve isn't on Home.
        let rec = displayDay?.recovery ?? 55
        let strain = displayDay?.strain ?? 0
        let strainPart = (strain / effortGaugeMax) * 1.4   // high day-strain nudges stress up
        let recoveryPart = max(0, (55 - rec) / 55) * 1.1  // only below-mid recovery adds stress
        let raw = max(0.4, min(2.8, 0.7 + strainPart + recoveryPart))
        return (raw * 10).rounded() / 10
    }

    private var stressLabel: String {
        switch stressLevel {
        case ..<1.0: return String(localized: "LOW")
        case ..<2.0: return String(localized: "MEDIUM")
        default: return String(localized: "HIGH")
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(alignment: .leading, spacing: WhoopIOSDesign.sectionGap) {
                        Color.clear.frame(height: 1).id(Self.topAnchorID)
                            .background(ScrollOffsetReader(minY: $scrollMinY))

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
                        .opacity(showCompactHeader ? 0.15 : 1)

                        metricRingsRow
                            .whoopCardAppear(index: 1, visible: cardsVisible)
                            .opacity(showCompactHeader ? 0 : 1)

                        statusBanner
                            .whoopCardAppear(index: 2, visible: cardsVisible)

                        insightCard
                            .whoopCardAppear(index: 3, visible: cardsVisible)

                        HStack(alignment: .top, spacing: 10) {
                            healthMonitorCard
                            stressMonitorCard
                        }
                        .whoopCardAppear(index: 4, visible: cardsVisible)

                        if selectedDayOffset == 0, displayDay?.recovery == nil {
                            calibrationCard
                                .whoopCardAppear(index: 5, visible: cardsVisible)
                        }

                        myDaySection
                            .whoopCardAppear(index: 6, visible: cardsVisible)

                        myDashboardSection
                            .whoopCardAppear(index: 7, visible: cardsVisible)

                        stressChartCard
                            .whoopCardAppear(index: 8, visible: cardsVisible)

                        strainRecoveryChartCard
                            .whoopCardAppear(index: 9, visible: cardsVisible)
                    }
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
                .whoopPageBackground()
                .refreshable {
                    await repo.refresh()
                    ringAnimationToken += 1
                }

                if showCompactHeader {
                    compactStickyHeader
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: showCompactHeader)
            .onChange(of: scrollMinY) { _, y in
                // Top anchor leaves the top when scrolled past ~rings+header.
                showCompactHeader = y < -160
            }
            .task(id: "\(repo.refreshSeq)-\(selectedDayOffset)") {
                await load()
                ringAnimationToken += 1
                if !cardsVisible {
                    withAnimation(WhoopIOSDesign.cardAppear) { cardsVisible = true }
                }
            }
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo(Self.topAnchorID, anchor: .top)
                }
            }
            .task {
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if args.contains("--whoople-scroll") {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation(.easeOut(duration: 0.45)) {
                        proxy.scrollTo("whoopHomeMyDay", anchor: .top)
                    }
                }
                if args.contains("--whoople-scroll-deep") {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation(.easeOut(duration: 0.45)) {
                        proxy.scrollTo("whoopHomeDashboard", anchor: .top)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .whoopPageBackground()
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

    // MARK: - Compact sticky header (006)

    private var compactStickyHeader: some View {
        HStack(spacing: 18) {
            compactRing(label: "SLEEP", fraction: sleepFraction, accent: WhoopIOSDesign.sleepBlue)
            compactRing(label: "RECOVERY", fraction: recoveryFraction, accent: WhoopIOSDesign.recoveryAccent(score: displayDay?.recovery))
            compactRing(label: "STRAIN", fraction: strainFraction, accent: WhoopIOSDesign.strainBlue)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, WhoopIOSDesign.pageMargin)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            WhoopIOSDesign.bgMid.opacity(0.94)
                .background(.ultraThinMaterial)
        )
    }

    private func compactRing(label: String, fraction: Double, accent: Color) -> some View {
        HStack(spacing: 6) {
            WhoopMetricRing(
                fraction: fraction,
                displayValue: 0,
                format: { _ in "" },
                accent: accent,
                size: .mini,
                animationToken: ringAnimationToken,
                showsCenterValue: false
            )
            Text(label)
                .font(WhoopType.caption(10))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
    }

    // MARK: - Rings

    private var sleepFraction: Double {
        let perf = restScore ?? displayDay.flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
        return (perf ?? 0) / 100
    }
    private var recoveryFraction: Double { (displayDay?.recovery ?? 0) / 100 }
    private var strainFraction: Double { (displayDay?.strain ?? 0) / effortGaugeMax }

    private var metricRingsRow: some View {
        HStack(alignment: .top, spacing: WhoopIOSDesign.homeRingGap) {
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
            animationToken: ringAnimationToken,
            valueSuffix: has ? "%" : nil
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
            animationToken: ringAnimationToken,
            valueSuffix: has ? "%" : nil
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

    // MARK: - Insight stack

    private var insightCard: some View {
        let cards = insightCards
        let idx = min(max(insightIndex, 0), max(cards.count - 1, 0))
        let current = cards.isEmpty ? (String(localized: "Building your baseline"), String(localized: "Wear your strap to unlock insights.")) : cards[idx]
        return ZStack {
            if cards.count > 1 {
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.cardRaised.opacity(0.55))
                    .offset(y: 8)
                    .padding(.horizontal, 6)
            }
            WhoopCard(raised: true) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(current.0)
                            .font(WhoopType.cardTitle())
                            .foregroundStyle(.white)
                        Spacer(minLength: 8)
                        if cards.count > 1 {
                            Button {
                                insightIndex = (idx + 1) % cards.count
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("\(idx + 1)/\(cards.count)")
                                        .font(WhoopType.caption(11))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(WhoopIOSDesign.card.opacity(0.9)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text(current.1)
                        .font(WhoopType.body())
                        .foregroundStyle(WhoopIOSDesign.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Monitors

    private var healthMonitorCard: some View {
        NavigationLink(value: TabRoute.health) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 10) {
                    WhoopSectionHeader("Health Monitor", showsChevron: true)
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                            .font(.system(size: 18, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WITHIN RANGE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                            Text("5/5 Metrics")
                                .font(WhoopType.caption())
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var stressMonitorCard: some View {
        NavigationLink(value: TabRoute.stress) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 10) {
                    WhoopSectionHeader("Stress Monitor", showsChevron: true)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(String(format: "%.1f", stressLevel))
                            .font(WhoopType.metric(22))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stressLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                            Text(stressTimeLabel)
                                .font(WhoopType.caption())
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var stressTimeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }

    // MARK: - Status banners

    @ViewBuilder private var statusBanner: some View {
        if let pct = model.live.batteryPct.map({ Int($0.rounded()) }), pct <= 15 {
            WhoopStatusBanner(
                icon: "battery.25",
                tint: WhoopIOSDesign.recoveryRed,
                title: String(localized: "Low Battery"),
                detail: String(localized: "\(pct)% — charge before bed")
            )
        } else if !model.live.connected, selectedDayOffset == 0 {
            WhoopStatusBanner(
                icon: "antenna.radiowaves.left.and.right.slash",
                tint: WhoopIOSDesign.recoveryYellow,
                title: String(localized: "Strap not connected"),
                detail: String(localized: "Open Devices to reconnect \(WhoopleBranding.displayName)")
            )
        }
    }

    // MARK: - My Day

    private var myDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Color.clear.frame(height: 0).id("whoopHomeMyDay")
            HStack {
                Text("My Day")
                    .font(WhoopType.title())
                    .foregroundStyle(.white)
                Spacer()
                Button { router.requestQuickActions() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to My Day")
            }

            tonightSleepCard
            activitiesCard
        }
    }

    private var tonightSleepCard: some View {
        NavigationLink(value: TabRoute.sleep) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 12) {
                    WhoopSectionHeader("Tonight's Sleep", showsChevron: true)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("RECOMMENDED BEDTIME")
                                .font(WhoopType.caption())
                                .tracking(0.8)
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                            HStack(spacing: 6) {
                                Image(systemName: "sunset.fill")
                                    .foregroundStyle(WhoopIOSDesign.recoveryYellow)
                                Text(recommendedBedtime)
                                    .font(WhoopType.metric(28))
                                    .foregroundStyle(.white)
                                    .monospacedDigit()
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(sleepNeedLabel)
                                .font(WhoopType.metric(22))
                                .foregroundStyle(.white)
                                .monospacedDigit()
                            Text("SLEEP NEED")
                                .font(WhoopType.caption())
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                    HStack {
                        Image(systemName: "pencil")
                        Text("EDIT ALARM")
                            .font(WhoopType.labelCaps())
                            .tracking(1)
                    }
                    .foregroundStyle(WhoopIOSDesign.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(WhoopIOSDesign.surfaceList))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var recommendedBedtime: String {
        // Aim ~7h45m before a 6:30 wake → ~10:45 PM when we lack planner data.
        "10:45"
    }

    private var sleepNeedLabel: String {
        if let mins = displayDay?.totalSleepMin {
            let need = max(420, mins + 30)
            return String(format: "%d:%02d", Int(need) / 60, Int(need) % 60)
        }
        return "7:45"
    }

    private var activitiesCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 12) {
                WhoopSectionHeader("Activities", showsChevron: false)
                if let sleepMins = displayDay?.totalSleepMin, sleepMins > 0 {
                    activityRow(
                        icon: "moon.fill",
                        tint: WhoopIOSDesign.sleepBlue,
                        title: "Sleep",
                        detail: formatDuration(sleepMins),
                        trailing: sleepWindowLabel
                    )
                }
                ForEach(Array(todayWorkouts.prefix(4).enumerated()), id: \.offset) { _, w in
                    activityRow(
                        icon: sportSymbol(w.sport),
                        tint: WhoopIOSDesign.strainBlue,
                        title: w.sport,
                        detail: w.strain.map { String(format: "%.1f", $0) }.map { "Strain \($0)" } ?? formatSeconds(w.durationS),
                        trailing: workoutTimeRange(w)
                    )
                }
                if todayWorkouts.isEmpty, (displayDay?.totalSleepMin ?? 0) <= 0 {
                    Text("No activities yet today")
                        .font(WhoopType.body(14))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                        .padding(.vertical, 4)
                }
                HStack(spacing: 10) {
                    NavigationLink(value: TabRoute.workouts) {
                        Label("ADD ACTIVITY", systemImage: "plus")
                            .font(WhoopType.labelCaps(11))
                            .tracking(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(WhoopIOSDesign.surfaceList))
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: TabRoute.workouts) {
                        Label("START ACTIVITY", systemImage: "timer")
                            .font(WhoopType.labelCaps(11))
                            .tracking(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(WhoopIOSDesign.surfaceList))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func activityRow(icon: String, tint: Color, title: String, detail: String, trailing: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.22))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(WhoopType.labelCaps(12))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(WhoopType.caption())
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer()
            Text(trailing)
                .font(WhoopType.caption())
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var sleepWindowLabel: String {
        "—"
    }

    private func workoutTimeRange(_ w: WorkoutRow) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let start = Date(timeIntervalSince1970: TimeInterval(w.startTs))
        let end = Date(timeIntervalSince1970: TimeInterval(w.endTs))
        return "\(f.string(from: start))\n\(f.string(from: end))"
    }

    private func formatDuration(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return String(format: "%d:%02d", h, m)
    }

    private func formatSeconds(_ seconds: Double?) -> String {
        guard let seconds else { return "—" }
        let m = Int(seconds) / 60
        return "\(m) min"
    }

    // MARK: - My Dashboard

    private var myDashboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color.clear.frame(height: 0).id("whoopHomeDashboard")
            HStack {
                Text("My Dashboard")
                    .font(WhoopType.title(20))
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink { WhoopDashboardView() } label: {
                    HStack(spacing: 4) {
                        Text("CUSTOMIZE")
                            .font(WhoopType.labelCaps(11))
                            .tracking(0.8)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .buttonStyle(.plain)
            }

            ForEach(dashboardRows) { row in
                NavigationLink(value: TabRoute.whoopTrend(row.metricKey)) {
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
        }
    }

    private struct DashRow: Identifiable {
        let id: String
        let metricKey: String
        let icon: String
        let title: String
        let value: String
        let baseline: String?
        let trend: WhoopTrendDirection
    }

    private var dashboardRows: [DashRow] {
        let day = displayDay
        let hrv = day?.avgHrv ?? vitalsDay?.avgHrv
        let hrvBase = repo.chargeBaselines?.hrv.baseline
        let rhr = day?.restingHr ?? vitalsDay?.restingHr
        let rhrBase = repo.chargeBaselines.map { Int($0.restingHR.baseline.rounded()) }
        let steps = day?.steps
        let kcal = day?.activeKcalEst

        func trend(current: Double?, baseline: Double?, higherIsBetter: Bool) -> WhoopTrendDirection {
            guard let current, let baseline, baseline > 0 else { return .flat }
            let delta = current - baseline
            if abs(delta / baseline) < 0.03 { return .flat }
            let up = delta > 0
            if higherIsBetter { return up ? .upGood : .downBad }
            return up ? .upBad : .downGood
        }

        return [
            DashRow(id: "rhr", metricKey: "rhr", icon: "heart.fill", title: "RESTING HEART RATE",
                    value: rhr.map { "\($0)" } ?? "—",
                    baseline: rhrBase.map { "\($0)" },
                    trend: trend(current: rhr.map(Double.init), baseline: rhrBase.map(Double.init), higherIsBetter: false)),
            DashRow(id: "steps", metricKey: "steps", icon: "figure.walk", title: "STEPS",
                    value: steps.map { Self.intFormatter.string(from: NSNumber(value: $0)) ?? "\($0)" } ?? "—",
                    baseline: "7,500",
                    trend: trend(current: steps.map(Double.init), baseline: 7500, higherIsBetter: true)),
            DashRow(id: "hrv", metricKey: "hrv", icon: "waveform.path.ecg", title: "HEART RATE VARIABILITY",
                    value: hrv.map { String(format: "%.0f" , $0) } ?? "—",
                    baseline: hrvBase.map { String(format: "%.0f", $0) },
                    trend: trend(current: hrv, baseline: hrvBase, higherIsBetter: true)),
            DashRow(id: "kcal", metricKey: "energy_kcal", icon: "flame.fill", title: "CALORIES",
                    value: kcal.map { Self.intFormatter.string(from: NSNumber(value: Int($0.rounded()))) ?? "\(Int($0))" } ?? "—",
                    baseline: "1,600",
                    trend: trend(current: kcal, baseline: 1600, higherIsBetter: true)),
        ]
    }

    private static let intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    // MARK: - Charts (simplified Phase 2 placeholders wired to real day series)

    private var stressChartCard: some View {
        NavigationLink(value: TabRoute.stress) {
            WhoopCard {
                VStack(alignment: .leading, spacing: 10) {
                    WhoopSectionHeader("Stress Monitor", showsChevron: true)
                    Text(String(format: "%.1f  ·  %@", stressLevel, stressLabel.capitalized))
                        .font(WhoopType.body(14))
                        .foregroundStyle(WhoopIOSDesign.textBody)
                    WhoopSparkline(
                        values: stressSparkValues,
                        tint: WhoopIOSDesign.recoveryGreen,
                        fill: WhoopIOSDesign.recoveryGreen.opacity(0.18)
                    )
                    .frame(height: 72)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var strainRecoveryChartCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 10) {
                WhoopSectionHeader("Strain & Recovery", showsChevron: false)
                HStack(spacing: 16) {
                    legendDot(WhoopIOSDesign.strainBlue, "Strain")
                    legendDot(WhoopIOSDesign.recoveryGreen, "Recovery")
                }
                WhoopDualSparkline(
                    primary: strainSparkValues,
                    secondary: recoverySparkValues,
                    primaryTint: WhoopIOSDesign.strainBlue,
                    secondaryTint: WhoopIOSDesign.recoveryGreen
                )
                .frame(height: 88)
            }
        }
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(WhoopType.caption())
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
    }

    private var stressSparkValues: [Double] {
        // Synthetic daytime curve shaped by today's stress level for visual parity.
        let peak = max(0.4, stressLevel)
        return (0..<24).map { h in
            let dayFactor = exp(-pow(Double(h - 14) / 6.0, 2))
            return max(0.1, peak * (0.35 + 0.65 * dayFactor))
        }
    }

    private var strainSparkValues: [Double] {
        let recent = repo.days.suffix(14)
        return recent.map { ($0.strain ?? 0) / effortGaugeMax }
    }

    private var recoverySparkValues: [Double] {
        let recent = repo.days.suffix(14)
        return recent.map { ($0.recovery ?? 0) / 100 }
    }

    // MARK: - Destinations / calibration / load

    @ViewBuilder private var sleepDestination: some View { WhoopSleepDetailView() }

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
                    .font(WhoopType.cardTitle())
                    .foregroundStyle(.white)
                Text("Wear \(WhoopleBranding.displayName) to sleep for a few nights to calibrate recovery, strain, and sleep scores.")
                    .font(WhoopType.body(14))
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
        insightIndex = 0

        let rows = await repo.workoutRows(days: 14)
        let dayStart = Calendar.current.date(byAdding: .day, value: -selectedDayOffset, to: Repository.logicalDay(Date())) ?? Date()
        let start = Calendar.current.startOfDay(for: dayStart)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let startTs = Int(start.timeIntervalSince1970)
        let endTs = Int(end.timeIntervalSince1970)
        todayWorkouts = rows
            .filter { $0.startTs >= startTs && $0.startTs < endTs }
            .sorted { $0.startTs > $1.startTs }
    }
}

// MARK: - Scroll offset

private struct ScrollOffsetReader: View {
    @Binding var minY: CGFloat
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { minY = geo.frame(in: .global).minY }
                .onChange(of: geo.frame(in: .global).origin.y) { _, y in
                    minY = y
                }
        }
    }
}

#endif
