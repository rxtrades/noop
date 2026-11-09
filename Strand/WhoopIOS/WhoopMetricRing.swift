#if os(iOS)
import SwiftUI
import StrandDesign

/// Shared Whoople metric ring — home / detail / mini sizes with ease-out fill + count-up.
struct WhoopMetricRing: View {
    enum Size {
        case home, detail, mini
        var diameter: CGFloat {
            switch self {
            case .home: return WhoopIOSDesign.homeRingDiameter
            case .detail: return WhoopIOSDesign.detailRingDiameter
            case .mini: return WhoopIOSDesign.miniRingDiameter
            }
        }
        var lineWidth: CGFloat {
            switch self {
            case .home: return WhoopIOSDesign.homeRingLineWidth
            case .detail: return WhoopIOSDesign.detailRingLineWidth
            case .mini: return WhoopIOSDesign.miniRingLineWidth
            }
        }
    }

    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var size: Size = .home
    /// Optional secondary suffix rendered smaller (e.g. "%").
    var valueSuffix: String? = nil
    /// White tick at the start of the arc (Strain detail).
    var showsStartTick: Bool = false
    var animationToken: Int = 0
    /// When false, centre value is omitted (caller draws custom centre content).
    var showsCenterValue: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedFraction: Double = 0
    @State private var shownValue: Double = 0

    private var targetFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WhoopIOSDesign.ringTrack,
                        style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: max(0.001, animatedFraction))
                .stroke(accent, style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showsStartTick {
                Circle()
                    .fill(Color.white)
                    .frame(width: size.lineWidth * 0.55, height: size.lineWidth * 0.55)
                    .offset(y: -size.diameter / 2)
            }
            if showsCenterValue {
                centerLabel
            }
        }
        .frame(width: size.diameter, height: size.diameter)
        .onAppear { animateToTarget() }
        .onChange(of: animationToken) { _, _ in animateToTarget() }
        .onChange(of: targetFraction) { _, _ in animateToTarget() }
        .onChange(of: displayValue) { _, _ in animateToTarget() }
    }

    @ViewBuilder private var centerLabel: some View {
        let base: CGFloat = size == .detail ? 64 : (size == .home ? 28 : 10)
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(format(shownValue))
                .font(WhoopType.ringValue(base))
                .foregroundStyle(WhoopIOSDesign.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
            if let valueSuffix {
                Text(valueSuffix)
                    .font(WhoopType.ringValue(base * 0.55))
                    .foregroundStyle(WhoopIOSDesign.textPrimary)
            }
        }
    }

    private func animateToTarget() {
        if reduceMotion {
            animatedFraction = targetFraction
            shownValue = displayValue
            return
        }
        animatedFraction = 0
        shownValue = 0
        withAnimation(WhoopIOSDesign.ringFill) {
            animatedFraction = targetFraction
            shownValue = displayValue
        }
    }
}

/// Home column: ring + UPPERCASE label + chevron.
struct WhoopMetricRingColumn: View {
    var label: LocalizedStringKey
    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var valueSuffix: String? = nil
    var showsStartTick: Bool = false
    var animationToken: Int = 0

    var body: some View {
        VStack(spacing: 10) {
            WhoopMetricRing(
                fraction: fraction,
                displayValue: displayValue,
                format: format,
                accent: accent,
                size: .home,
                valueSuffix: valueSuffix,
                showsStartTick: showsStartTick,
                animationToken: animationToken
            )
            HStack(spacing: 3) {
                Text(label)
                    .font(WhoopType.labelCaps())
                    .tracking(WhoopType.labelTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#endif
