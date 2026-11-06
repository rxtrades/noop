#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// Stress Monitor detail (Mobbin 059): semicircle gauge + day summary.
struct WhoopStressMonitorView: View {
    @EnvironmentObject private var repo: Repository
    @State private var day: DailyMetric?

    private var level: Double {
        let rec = day?.recovery ?? 50
        let strain = day?.strain ?? 0
        let maxS: Double = 100
        return min(3, max(0, (strain / maxS) * 1.4 + max(0, (55 - rec) / 55) * 1.1))
    }

    private var label: String {
        switch level {
        case ..<1: return "LOW"
        case ..<2: return "MEDIUM"
        default: return "HIGH"
        }
    }

    private var labelColor: Color {
        switch level {
        case ..<1: return WhoopIOSDesign.strainBlue
        case ..<2: return WhoopIOSDesign.recoveryGreen
        default: return WhoopIOSDesign.stressHigh
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WhoopStressGauge(level: level, diameter: 260)
                    .overlay(alignment: .center) {
                        VStack(spacing: 6) {
                            Text(String(format: "%.1f", level))
                                .font(WhoopType.hero(48))
                                .foregroundStyle(.white)
                            Text(label)
                                .font(WhoopType.labelCaps(14))
                                .tracking(1.2)
                                .foregroundStyle(labelColor)
                        }
                        .offset(y: 28)
                    }
                    .padding(.top, 12)

                WhoopCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TOTAL DAY")
                            .font(WhoopType.rowCaps(12))
                            .tracking(0.8)
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        Text("Heuristic from today’s recovery and strain. A live daytime stress curve lands when the strap stream is available.")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.textBody)
                        HStack {
                            stat("LEVEL", String(format: "%.1f", level))
                            stat("BAND", label.capitalized)
                            stat("SCALE", "0–3")
                        }
                    }
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)

                WhoopCoachCard(message: "Stress here is a soft estimate so you can scan load at a glance. Pair it with Recovery before you push hard.")
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
            }
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationTitle("Stress Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            day = repo.today ?? repo.days.last
        }
    }

    private func stat(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t)
                .font(WhoopType.caption(10))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Text(v)
                .font(WhoopType.metric(20))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WhoopStressGauge: View {
    var level: Double // 0...3
    var diameter: CGFloat = 200

    var body: some View {
        let frac = min(1, max(0, level / 3))
        ZStack {
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    AngularGradient(
                        colors: [WhoopIOSDesign.strainBlue, WhoopIOSDesign.recoveryGreen, WhoopIOSDesign.stressHigh],
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: max(8, diameter * 0.06), lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .opacity(0.35)
                .frame(width: diameter, height: diameter)
            Circle()
                .trim(from: 0.08, to: 0.08 + 0.84 * frac)
                .stroke(
                    AngularGradient(
                        colors: [WhoopIOSDesign.strainBlue, WhoopIOSDesign.recoveryGreen, WhoopIOSDesign.stressHigh],
                        center: .center,
                        startAngle: .degrees(180),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: max(8, diameter * 0.06), lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .frame(width: diameter, height: diameter)
            HStack {
                Text("0.0").font(WhoopType.caption(10)).foregroundStyle(WhoopIOSDesign.textTertiary)
                Spacer()
                Text("3.0").font(WhoopType.caption(10)).foregroundStyle(WhoopIOSDesign.textTertiary)
            }
            .frame(width: diameter * 0.85)
            .offset(y: diameter * 0.38)
        }
        .frame(width: diameter, height: diameter * 0.72)
    }
}

#endif
