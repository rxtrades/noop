#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP Health tab (Mobbin 073): purple header, Advanced Labs, Health Monitor grid, Stress entry, Weekly Trends.
struct WhoopHealthTabView: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var model: AppModel

    @State private var day: DailyMetric?
    @State private var vitals: DailyMetric?

    private var hrv: Double? { day?.avgHrv ?? vitals?.avgHrv }
    private var rhr: Int? { day?.restingHr ?? vitals?.restingHr }
    private var resp: Double? { day?.respRateBpm ?? vitals?.respRateBpm }
    private var spo2: Double? { day?.spo2Pct ?? vitals?.spo2Pct }
    private var tempDev: Double? { day?.skinTempDevC ?? vitals?.skinTempDevC }

    private var inRangeCount: Int {
        [hrv != nil, rhr != nil, resp != nil, spo2 != nil, tempDev != nil].filter { $0 }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("HEALTH")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.4)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                advancedLabsCard
                healthMonitorCard
                stressEntryCard

                NavigationLink(value: TabRoute.whoopTrend("recovery")) {
                    EmptyView()
                }.hidden()

                NavigationLink {
                    WhoopWeeklyTrendsView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WEEKLY TRENDS")
                                .font(WhoopType.rowCaps(13))
                                .tracking(0.8)
                                .foregroundStyle(.white)
                            Text("Recovery, HRV, RHR, Strain, Sleep")
                                .font(WhoopType.caption(12))
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(WhoopIOSDesign.textTertiary)
                    }
                    .padding(16)
                    .background(cardBG)
                }
                .buttonStyle(.plain)

                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
        }
        .background(healthBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .task { await reload() }
        .onChange(of: repo.refreshSeq) { _, _ in Task { await reload() } }
    }

    private var healthBackground: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#2B2350"), location: 0),
                .init(color: Color(hex: "#1A1830"), location: 0.28),
                .init(color: WhoopIOSDesign.bgMid, location: 0.55),
                .init(color: WhoopIOSDesign.bgBottom, location: 1)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
            .fill(WhoopIOSDesign.card.opacity(0.95))
    }

    private var advancedLabsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ADVANCED LABS")
                    .font(WhoopType.rowCaps(13))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(WhoopIOSDesign.textTertiary)
            }
            HStack(alignment: .top, spacing: 12) {
                Text("Get deeper health insights by integrating lab results with your Whoople data.")
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(colors: [WhoopIOSDesign.recoveryGreen, WhoopIOSDesign.stressHigh, WhoopIOSDesign.strainBlue, WhoopIOSDesign.recoveryGreen], center: .center),
                            lineWidth: 6
                        )
                        .frame(width: 64, height: 64)
                    Image(systemName: "testtube.2")
                        .foregroundStyle(.white)
                }
            }
            Text("GET STARTED →")
                .font(WhoopType.labelCaps(12))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.strainBlue)
        }
        .padding(16)
        .background(cardBG)
    }

    private var healthMonitorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("HEALTH MONITOR")
                    .font(WhoopType.rowCaps(13))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(WhoopIOSDesign.textTertiary)
            }
            HStack(spacing: 0) {
                vitalTile("RESP", "lungs.fill", resp.map { String(format: "%.0f", $0) } ?? "—")
                vitalTile("SPO₂", "drop.fill", spo2.map { String(format: "%.0f%%", $0) } ?? "—")
                vitalTile("RHR", "heart.fill", rhr.map { "\($0)" } ?? "—")
                vitalTile("HRV", "waveform.path.ecg", hrv.map { String(format: "%.0f", $0) } ?? "—")
                vitalTile("TEMP", "thermometer.medium", tempDev.map { String(format: "%+.1f°", $0) } ?? "—")
            }
            HStack(spacing: 8) {
                Image(systemName: "checkmark.square.fill")
                    .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                Text("\(inRangeCount)/5 metrics with data")
                    .font(WhoopType.caption(12))
                    .foregroundStyle(WhoopIOSDesign.textBody)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.35)))
        }
        .padding(16)
        .background(cardBG)
    }

    private func vitalTile(_ title: String, _ icon: String, _ value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(title)
                .font(WhoopType.caption(10))
                .tracking(0.6)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Image(systemName: value == "—" ? "minus.square" : "checkmark.square.fill")
                .foregroundStyle(value == "—" ? WhoopIOSDesign.textTertiary : WhoopIOSDesign.recoveryGreen)
                .font(.system(size: 14))
            Text(value)
                .font(WhoopType.caption(11))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var stressEntryCard: some View {
        NavigationLink {
            WhoopStressMonitorView()
        } label: {
            HStack(spacing: 14) {
                WhoopStressGauge(level: stressLevel, diameter: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text("STRESS MONITOR")
                        .font(WhoopType.rowCaps(13))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                    Text(String(format: "%.1f · %@", stressLevel, stressLabel))
                        .font(WhoopType.body(15))
                        .foregroundStyle(WhoopIOSDesign.textBody)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(WhoopIOSDesign.textTertiary)
            }
            .padding(16)
            .background(cardBG)
        }
        .buttonStyle(.plain)
    }

    private var stressLevel: Double {
        let rec = day?.recovery ?? 50
        let strain = day?.strain ?? 0
        let maxS: Double = 100
        let strainPart = (strain / maxS) * 1.4
        let recoveryPart = max(0, (55 - rec) / 55) * 1.1
        return min(3, max(0, strainPart + recoveryPart))
    }

    private var stressLabel: String {
        switch stressLevel {
        case ..<1: return "Low"
        case ..<2: return "Medium"
        default: return "High"
        }
    }

    private func reload() async {
        day = repo.today ?? repo.days.last
        vitals = Repository.lastVitalsDay(days: repo.days) ?? day
    }
}

#endif
