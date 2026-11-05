#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP "My Dashboard" style metric list — reuses stored daily values, dark card rows.
struct WhoopDashboardView: View {
    @EnvironmentObject private var repo: Repository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                Text("My Dashboard")
                    .font(StrandFont.title1)
                    .foregroundStyle(StrandPalette.textPrimary)
                WhoopCard {
                    VStack(spacing: 0) {
                        if let today = repo.today ?? repo.days.last {
                            dashboardRow("Recovery", value: today.recovery.map { "\(Int($0.rounded()))%" } ?? "—",
                                         accent: today.recovery.map { StrandPalette.recoveryColor($0) } ?? StrandPalette.textSecondary)
                            rowDivider
                            dashboardRow("Day Strain", value: today.strain.map { String(format: "%.1f", $0) } ?? "—",
                                         accent: StrandPalette.effortColor)
                            rowDivider
                            dashboardRow("Sleep", value: today.totalSleepMin.map { formatSleep($0) } ?? "—",
                                         accent: WhoopIOSDesign.sleepBlue)
                            rowDivider
                            dashboardRow("HRV", value: today.avgHrv.map { String(format: "%.0f ms", $0) } ?? "—",
                                         accent: StrandPalette.metricCyan)
                            rowDivider
                            dashboardRow("Resting HR", value: today.restingHr.map { "\($0) bpm" } ?? "—",
                                         accent: StrandPalette.metricRose)
                        } else {
                            Text("Wear your strap and sync to populate dashboard metrics.")
                                .font(StrandFont.body)
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                }
                NavigationLink(value: TabRoute.metricExplorer) {
                    WhoopCard {
                        WhoopSectionHeader("Explore all metrics")
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, NoopMetrics.screenHPadding)
            .padding(.top, 12)
            .padding(.bottom, NoopMetrics.tabBarClearance + 24)
        }
        .background(WhoopIOSDesign.background.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dashboardRow(_ title: LocalizedStringKey, value: String, accent: Color) -> some View {
        HStack {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
            Text(title)
                .font(StrandFont.headline)
                .foregroundStyle(StrandPalette.textPrimary)
            Spacer(minLength: 8)
            Text(value)
                .font(StrandFont.number(17, weight: .semibold))
                .foregroundStyle(StrandPalette.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle().fill(StrandPalette.hairline).frame(height: 0.5)
    }

    private func formatSleep(_ minutes: Double) -> String {
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return String(format: "%d:%02d", h, m)
    }
}

#endif
