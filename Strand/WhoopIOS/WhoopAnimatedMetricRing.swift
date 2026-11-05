#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-style ring: thick track, spring fill, optional strain gradient, count-up centre value.
struct WhoopAnimatedMetricRing: View {
    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var useStrainGradient: Bool
    var diameter: CGFloat
    var lineWidth: CGFloat
    /// Bump to re-run the fill animation after refresh.
    var animationToken: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedFraction: Double = 0
    @State private var shownValue: Double = 0

    init(
        fraction: Double,
        displayValue: Double,
        format: @escaping (Double) -> String,
        accent: Color,
        useStrainGradient: Bool = false,
        diameter: CGFloat = 104,
        lineWidth: CGFloat = 9,
        animationToken: Int = 0
    ) {
        self.fraction = fraction
        self.displayValue = displayValue
        self.format = format
        self.accent = accent
        self.useStrainGradient = useStrainGradient
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.animationToken = animationToken
    }

    private var targetFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WhoopIOSDesign.cardElevated.opacity(0.9),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            ringArc
            Text(format(shownValue))
                .font(GlowRing.centerFont(diameter: diameter))
                .foregroundStyle(StrandPalette.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .frame(width: diameter, height: diameter)
        .onAppear { animateToTarget() }
        .onChange(of: animationToken) { _, _ in animateToTarget() }
        .onChange(of: targetFraction) { _, _ in animateToTarget() }
    }

    @ViewBuilder private var ringArc: some View {
        let trim = max(0.001, animatedFraction)
        if useStrainGradient {
            Circle()
                .trim(from: 0, to: trim)
                .stroke(WhoopIOSDesign.strainGradient(),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        } else {
            Circle()
                .trim(from: 0, to: trim)
                .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
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
        withAnimation(WhoopIOSDesign.ringSpring) {
            animatedFraction = targetFraction
            shownValue = displayValue
        }
    }
}

struct WhoopAnimatedMetricRingColumn: View {
    var label: LocalizedStringKey
    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var useStrainGradient: Bool
    var animationToken: Int

    var body: some View {
        VStack(spacing: 10) {
            WhoopAnimatedMetricRing(
                fraction: fraction,
                displayValue: displayValue,
                format: format,
                accent: accent,
                useStrainGradient: useStrainGradient,
                animationToken: animationToken
            )
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#endif
