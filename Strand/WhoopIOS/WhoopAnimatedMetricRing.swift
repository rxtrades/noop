#if os(iOS)
import SwiftUI
import StrandDesign

/// Compatibility wrapper — prefer `WhoopMetricRing` / `WhoopMetricRingColumn`.
struct WhoopAnimatedMetricRing: View {
    var fraction: Double
    var displayValue: Double
    var format: (Double) -> String
    var accent: Color
    var useStrainGradient: Bool
    var diameter: CGFloat
    var lineWidth: CGFloat
    var animationToken: Int
    var valueSuffix: String? = nil
    var showsStartTick: Bool = false

    init(
        fraction: Double,
        displayValue: Double,
        format: @escaping (Double) -> String,
        accent: Color,
        useStrainGradient: Bool = false,
        diameter: CGFloat = WhoopIOSDesign.homeRingDiameter,
        lineWidth: CGFloat = WhoopIOSDesign.homeRingLineWidth,
        animationToken: Int = 0,
        valueSuffix: String? = nil,
        showsStartTick: Bool = false
    ) {
        self.fraction = fraction
        self.displayValue = displayValue
        self.format = format
        self.accent = useStrainGradient ? WhoopIOSDesign.strainBlue : accent
        self.useStrainGradient = useStrainGradient
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.animationToken = animationToken
        self.valueSuffix = valueSuffix
        self.showsStartTick = showsStartTick
    }

    var body: some View {
        let size: WhoopMetricRing.Size = {
            if abs(diameter - WhoopIOSDesign.detailRingDiameter) < 2 { return .detail }
            if abs(diameter - WhoopIOSDesign.miniRingDiameter) < 2 { return .mini }
            return .home
        }()
        WhoopMetricRing(
            fraction: fraction,
            displayValue: displayValue,
            format: format,
            accent: accent,
            size: size,
            valueSuffix: valueSuffix,
            showsStartTick: showsStartTick || useStrainGradient,
            animationToken: animationToken
        )
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
    var valueSuffix: String? = nil

    var body: some View {
        WhoopMetricRingColumn(
            label: label,
            fraction: fraction,
            displayValue: displayValue,
            format: format,
            accent: useStrainGradient ? WhoopIOSDesign.strainBlue : accent,
            valueSuffix: valueSuffix,
            showsStartTick: useStrainGradient,
            animationToken: animationToken
        )
    }
}

#endif
