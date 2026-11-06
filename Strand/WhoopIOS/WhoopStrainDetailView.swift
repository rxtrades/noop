#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-inspired strain detail: blue hero ring + activity summary rows.
struct WhoopStrainDetailView: View {
    var strain: Double?
    var steps: Int?
    var hrZoneMinutes: Int?
    var strengthMinutes: Int?
    var outOf: Double = 21

    private var value: Double { strain ?? 0 }
    private var fraction: Double {
        guard outOf > 0 else { return 0 }
        return min(max(value / outOf, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    WhoopleWordmark(size: 13)
                    ZStack {
                        Circle()
                            .stroke(StrandPalette.surfaceInset, lineWidth: 18)
                        Circle()
                            .trim(from: 0, to: CGFloat(fraction))
                            .stroke(
                                WhoopIOSDesign.strainBlue,
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 4) {
                            Text(strain.map { String(format: "%.1f", $0) } ?? "—")
                                .font(StrandFont.display(56))
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text("STRAIN")
                                .font(StrandFont.overline)
                                .tracking(StrandFont.overlineTracking)
                                .textCase(.uppercase)
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    .frame(width: 260, height: 260)
                    Text(StrainGauge.stateLabel(forFraction: fraction))
                        .font(StrandFont.overline)
                        .tracking(StrandFont.overlineTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                WhoopMetricsBeakCard {
                    WhoopStrainStatRow(icon: "heart.text.square", label: "Heart Rate Zones 1–3",
                                       value: hrZoneMinutes.map { formatDuration($0) } ?? "—")
                    strainDivider
                    WhoopStrainStatRow(icon: "dumbbell.fill", label: "Strength Activity",
                                       value: strengthMinutes.map { formatDuration($0) } ?? "—")
                    strainDivider
                    WhoopStrainStatRow(icon: "figure.walk", label: "Steps",
                                       value: steps.map { formatSteps($0) } ?? "—")
                }
                .padding(.horizontal, NoopMetrics.screenHPadding)
            }
            .padding(.bottom, NoopMetrics.tabBarClearance + 24)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(StrandPalette.surfaceBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var strainDivider: some View {
        Rectangle()
            .fill(StrandPalette.hairline)
            .frame(height: 0.5)
            .padding(.leading, 44)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return String(format: "%d:%02d", h, m) }
        return "0:\(String(format: "%02d", m))"
    }

    private func formatSteps(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

private struct WhoopStrainStatRow: View {
    var icon: String
    var label: LocalizedStringKey
    var value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(StrandPalette.textSecondary)
                .frame(width: 28)
            Text(label)
                .font(StrandFont.caption)
                .textCase(.uppercase)
                .foregroundStyle(StrandPalette.textTertiary)
            Spacer(minLength: 8)
            Text(value)
                .font(StrandFont.number(26, weight: .bold))
                .foregroundStyle(StrandPalette.textPrimary)
        }
        .padding(.vertical, 14)
    }
}

#endif
