#if os(iOS)
import SwiftUI
import StrandDesign

/// Shared Mobbin detail chrome: date nav title, mini-ring trailing badge, hero ring, coach card.
enum WhoopDetailChrome {
    static var dateRangeLabel: String {
        let cal = Calendar.current
        let today = Date()
        guard let start = cal.date(byAdding: .day, value: -30, to: today) else {
            return String(localized: "TODAY").uppercased()
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: start).uppercased()) TO TODAY"
    }
}

struct WhoopDetailNavModifier: ViewModifier {
    var dateLabel: String = WhoopDetailChrome.dateRangeLabel
    var miniFraction: Double
    var miniAccent: Color
    var miniValue: String

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(dateLabel)
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.0)
                        .foregroundStyle(WhoopIOSDesign.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        WhoopMetricRing(
                            fraction: miniFraction,
                            displayValue: 0,
                            format: { _ in "" },
                            accent: miniAccent,
                            size: .mini,
                            animationToken: 0,
                            showsCenterValue: false
                        )
                        Text(miniValue)
                            .font(WhoopType.caption(12))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(WhoopIOSDesign.cardRaised))
                }
            }
            .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func whoopDetailNav(miniFraction: Double, miniAccent: Color, miniValue: String,
                        dateLabel: String = WhoopDetailChrome.dateRangeLabel) -> some View {
        modifier(WhoopDetailNavModifier(
            dateLabel: dateLabel,
            miniFraction: miniFraction,
            miniAccent: miniAccent,
            miniValue: miniValue
        ))
    }
}

/// Large detail ring with Whoople wordmark + value + caps label inside (Mobbin 039/085/032).
struct WhoopDetailHeroRing: View {
    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var label: String
    var valueSuffix: String? = nil
    var showsStartTick: Bool = false
    var legend: WhoopSleepBandLegend? = nil
    var animationToken: Int = 0

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                WhoopMetricRing(
                    fraction: fraction,
                    displayValue: displayValue,
                    format: format,
                    accent: accent,
                    size: .detail,
                    valueSuffix: valueSuffix,
                    showsStartTick: showsStartTick,
                    animationToken: animationToken,
                    showsCenterValue: false
                )
                VStack(spacing: 4) {
                    WhoopleWordmark(size: 12)
                        .opacity(0.55)
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(format(displayValue))
                            .font(WhoopType.hero(64))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        if let valueSuffix {
                            Text(valueSuffix)
                                .font(WhoopType.hero(32))
                                .foregroundStyle(.white)
                        }
                    }
                    Text(label)
                        .font(WhoopType.labelCaps(12))
                        .tracking(WhoopType.labelTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.9))
                    if let legend {
                        legend
                            .padding(.top, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct WhoopSleepBandLegend: View {
    var activeBand: Int // 0 poor, 1 sufficient, 2 optimal; -1 none

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(bandColor(i))
                    .frame(width: 22, height: 5)
            }
        }
    }

    private func bandColor(_ i: Int) -> Color {
        if i == activeBand {
            switch i {
            case 0: return WhoopIOSDesign.trendDown
            case 1: return WhoopIOSDesign.textTertiary
            default: return WhoopIOSDesign.recoveryGreen
            }
        }
        return WhoopIOSDesign.ringTrack
    }
}

struct WhoopCoachCard: View {
    var message: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(WhoopIOSDesign.cardRaised)
                        .frame(width: 36, height: 36)
                    Text("W")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [WhoopIOSDesign.fabGlowPurple, WhoopIOSDesign.fabGlowBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                Text(message)
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [WhoopIOSDesign.fabGlowPurple.opacity(0.55),
                                             WhoopIOSDesign.fabGlowBlue.opacity(0.4)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct WhoopVsBaselineLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 8))
                .foregroundStyle(WhoopIOSDesign.trendUp)
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundStyle(WhoopIOSDesign.trendDown)
            Text(WhoopDetailChrome.dateRangeLabel.capitalized + " vs. last 30 days")
                .font(WhoopType.caption(11))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(WhoopIOSDesign.cardRaised.opacity(0.85)))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

/// Sleep metric row with mini 3-band bar + percent (Mobbin 032).
struct WhoopSleepBarRow: View {
    var icon: String
    var label: String
    var percent: Double?
    var band: Int // 0 poor, 1 sufficient, 2 optimal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(width: 26)
            Text(label)
                .font(WhoopType.rowCaps(12))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            WhoopSleepBandLegend(activeBand: band)
            Text(percent.map { "\(Int($0.rounded()))%" } ?? "—")
                .font(WhoopType.metric(17))
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
    }
}

/// Simplified stage hypnogram from deep/rem/light/awake minutes.
struct WhoopHypnogramView: View {
    var deepMin: Double
    var remMin: Double
    var lightMin: Double
    var awakeMin: Double

    private var total: Double { max(deepMin + remMin + lightMin + awakeMin, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                let w = geo.size.width
                HStack(spacing: 0) {
                    stage(width: w * awakeMin / total, color: WhoopIOSDesign.recoveryYellow.opacity(0.85))
                    stage(width: w * lightMin / total, color: WhoopIOSDesign.sleepBlue.opacity(0.55))
                    stage(width: w * deepMin / total, color: WhoopIOSDesign.sleepBlue)
                    stage(width: w * remMin / total, color: Color(hex: "#9B7BDB"))
                }
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(height: 56)
            HStack(spacing: 12) {
                legend(WhoopIOSDesign.recoveryYellow.opacity(0.85), "Awake")
                legend(WhoopIOSDesign.sleepBlue.opacity(0.55), "Light")
                legend(WhoopIOSDesign.sleepBlue, "SWS")
                legend(Color(hex: "#9B7BDB"), "REM")
            }
        }
    }

    private func stage(width: CGFloat, color: Color) -> some View {
        Rectangle().fill(color).frame(width: max(width, 0))
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
                .font(WhoopType.caption(10))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
    }
}

struct WhoopEfficiencyBar: View {
    var efficiency: Double // 0...100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SLEEP EFFICIENCY")
                    .font(WhoopType.rowCaps(12))
                    .tracking(0.8)
                    .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
                Spacer()
                Text("\(Int(efficiency.rounded()))%")
                    .font(WhoopType.metric(17))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                let asleep = min(max(efficiency / 100, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(WhoopIOSDesign.ringTrack)
                    Capsule().fill(WhoopIOSDesign.recoveryGreen)
                        .frame(width: geo.size.width * asleep)
                }
            }
            .frame(height: 10)
            HStack {
                Text("Asleep")
                    .font(WhoopType.caption())
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                Spacer()
                Text("In bed")
                    .font(WhoopType.caption())
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }
}

#endif
