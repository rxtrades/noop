#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP-inspired recovery detail: hero ring + vitals rows with trend chevrons.
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

    private var score: Double { recovery ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    WhoopleWordmark(size: 13)
                    ZStack {
                        Circle()
                            .stroke(StrandPalette.surfaceInset, lineWidth: 18)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(max(score / 100, 0), 1)))
                            .stroke(
                                WhoopIOSDesign.recoveryAccent(score: score),
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 4) {
                            Text(recovery.map { "\(Int($0.rounded()))%" } ?? "—")
                                .font(StrandFont.display(56))
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text("RECOVERY")
                                .font(StrandFont.overline)
                                .tracking(StrandFont.overlineTracking)
                                .textCase(.uppercase)
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    .frame(width: 260, height: 260)
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)

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
                }
                .padding(.horizontal, NoopMetrics.screenHPadding)
            }
            .padding(.bottom, NoopMetrics.tabBarClearance + 24)
        }
        .background(WhoopIOSDesign.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(StrandPalette.surfaceBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var divider: some View {
        Rectangle()
            .fill(StrandPalette.hairline)
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
            }
            .background(
                RoundedRectangle(cornerRadius: NoopVisualStyle.cardRadius, style: .continuous)
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
                .font(.system(size: 16))
                .foregroundStyle(StrandPalette.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(StrandFont.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(StrandFont.number(28, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                if let baseline, let current {
                    WhoopTrendBadge(current: current, baseline: baseline, higherIsBetter: higherIsBetter,
                                    suffix: "")
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
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

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: delta >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 8))
            Text("\(Int(baseline.rounded()))\(suffix)")
                .font(StrandFont.caption)
        }
        .foregroundStyle(improved ? StrandPalette.statusPositive : StrandPalette.statusWarning)
    }
}

#endif
