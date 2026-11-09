#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP-inspired recovery detail: hero ring + vitals rows with baseline arrows + Coach card.
struct WhoopRecoveryDetailView: View {
    let recovery: Double?
    let hrv: Double?
    let rhr: Int?
    let respRate: Double?
    let sleepPerf: Double?
    let hrvBaseline: Double?
    let rhrBaseline: Int?
    let respBaseline: Double?
    let sleepBaseline: Double?

    @EnvironmentObject private var router: NavRouter
    @State private var ringToken = 0

    private var score: Double { recovery ?? 0 }
    private var fraction: Double { min(max(score / 100, 0), 1) }
    private var accent: Color { WhoopIOSDesign.recoveryAccent(score: recovery) }
    private var isCalibrating: Bool { recovery == nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                WhoopDetailHeroRing(
                    fraction: isCalibrating ? 0.54 : fraction,
                    displayValue: score,
                    format: { isCalibrating ? "—" : "\(Int($0.rounded()))" },
                    accent: isCalibrating ? WhoopIOSDesign.textTertiary : accent,
                    label: "Recovery",
                    valueSuffix: isCalibrating ? nil : "%",
                    animationToken: ringToken
                )

                if isCalibrating {
                    WhoopCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calibration in progress")
                                .font(WhoopType.cardTitle())
                                .foregroundStyle(.white)
                            Text("Wear \(WhoopleBranding.displayName) to sleep for a few more nights to unlock recovery drivers.")
                                .font(WhoopType.body(14))
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
                }

                WhoopMetricsBeakCard {
                    WhoopMetricTrendRow(
                        icon: "waveform.path.ecg",
                        label: "Heart Rate Variability",
                        value: hrv.map { String(format: "%.0f", $0) } ?? "—",
                        current: hrv,
                        baseline: hrvBaseline,
                        higherIsBetter: true
                    )
                    divider
                    WhoopMetricTrendRow(
                        icon: "heart.fill",
                        label: "Resting Heart Rate",
                        value: rhr.map { "\($0)" } ?? "—",
                        current: rhr.map(Double.init),
                        baseline: rhrBaseline.map(Double.init),
                        higherIsBetter: false
                    )
                    divider
                    WhoopMetricTrendRow(
                        icon: "lungs.fill",
                        label: "Respiratory Rate",
                        value: respRate.map { String(format: "%.1f", $0) } ?? "—",
                        current: respRate,
                        baseline: respBaseline,
                        higherIsBetter: false
                    )
                    divider
                    WhoopMetricTrendRow(
                        icon: "moon.fill",
                        label: "Sleep Performance",
                        value: sleepPerf.map { "\(Int($0.rounded()))%" } ?? "—",
                        current: sleepPerf,
                        baseline: sleepBaseline,
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
            miniAccent: isCalibrating ? WhoopIOSDesign.textTertiary : accent,
            miniValue: recovery.map { "\(Int($0.rounded()))" } ?? "—"
        )
        .task { ringToken += 1 }
    }

    private var coachMessage: String {
        if let recovery {
            if recovery >= 67 {
                return String(localized: "Strong recovery — your system looks resilient. A solid strain day is on the table if sleep holds.")
            }
            if recovery >= 34 {
                return String(localized: "Moderate recovery. Train inside today's strain budget and protect tonight's bedtime window.")
            }
            return String(localized: "Recovery needs rest. Keep strain light and prioritize sleep consistency tonight.")
        }
        return String(localized: "Still calibrating. Keep wearing \(WhoopleBranding.displayName) overnight to unlock recovery coaching.")
    }

    private var divider: some View {
        Rectangle()
            .fill(WhoopIOSDesign.cardBorder)
            .frame(height: 0.5)
            .padding(.leading, 44)
    }
}

struct WhoopMetricsBeakCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Triangle()
                .fill(WhoopIOSDesign.card)
                .frame(width: 18, height: 10)
            VStack(spacing: 0) {
                content()
                    .padding(.horizontal, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.card)
            )
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct WhoopMetricTrendRow: View {
    var icon: String
    var label: LocalizedStringKey
    var value: String
    var current: Double?
    var baseline: Double?
    var higherIsBetter: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(width: 28)
            Text(label)
                .font(WhoopType.rowCaps(12))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(WhoopType.metric(20))
                    .foregroundStyle(WhoopIOSDesign.textPrimary)
                    .monospacedDigit()
                if let baseline, let current {
                    WhoopTrendBadge(current: current, baseline: baseline, higherIsBetter: higherIsBetter, suffix: "")
                }
            }
        }
        .frame(minHeight: WhoopIOSDesign.rowHeight)
        .padding(.vertical, 4)
    }
}

struct WhoopTrendBadge: View {
    var current: Double
    var baseline: Double
    var higherIsBetter: Bool
    var suffix: String

    private var delta: Double { current - baseline }
    private var improved: Bool {
        if higherIsBetter { return delta >= 0 } else { return delta <= 0 }
    }

    private var isFlat: Bool {
        guard baseline != 0 else { return abs(delta) < 0.5 }
        return abs(delta / baseline) < 0.03
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isFlat ? "circle.fill" : (delta >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill"))
                .font(.system(size: isFlat ? 5 : 8, weight: .bold))
            Text("\(formatBaseline)\(suffix)")
                .font(WhoopType.caption(11))
                .monospacedDigit()
        }
        .foregroundStyle(isFlat ? WhoopIOSDesign.textTertiary : (improved ? WhoopIOSDesign.trendUp : WhoopIOSDesign.trendDown))
    }

    private var formatBaseline: String {
        if baseline == floor(baseline) { return "\(Int(baseline.rounded()))" }
        return String(format: "%.1f", baseline)
    }
}

#endif
