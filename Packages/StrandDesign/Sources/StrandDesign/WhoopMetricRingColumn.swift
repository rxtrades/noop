import SwiftUI

// MARK: - WHOOP-style metric ring column
//
// A full-circle progress ring with a large centred value, an all-caps label, and an optional chevron.
// Used on the iOS WHOOP-inspired home row (Sleep · Recovery · Strain).

public struct WhoopMetricRingColumn: View {

    public var label: LocalizedStringKey
    public var fraction: Double
    public var displayValue: Double
    public var format: (Double) -> String
    public var accent: Color
    public var diameter: CGFloat
    public var showsChevron: Bool

    public init(
        label: LocalizedStringKey,
        fraction: Double,
        displayValue: Double,
        format: @escaping (Double) -> String,
        accent: Color,
        diameter: CGFloat = 92,
        showsChevron: Bool = true
    ) {
        self.label = label
        self.fraction = fraction
        self.displayValue = displayValue
        self.format = format
        self.accent = accent
        self.diameter = diameter
        self.showsChevron = showsChevron
    }

    public var body: some View {
        VStack(spacing: 10) {
            GlowRing(
                fraction: fraction,
                value: displayValue,
                format: format,
                color: accent,
                diameter: diameter,
                lineWidth: max(7, diameter * 0.075)
            )
            HStack(spacing: 4) {
                Text(label)
                    .font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(StrandPalette.textSecondary)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(StrandPalette.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("WhoopMetricRingColumn") {
    HStack {
        WhoopMetricRingColumn(
            label: "Recovery",
            fraction: 0.86,
            displayValue: 86,
            format: { "\(Int($0.rounded()))" },
            accent: StrandPalette.recoveryColor(86)
        )
        WhoopMetricRingColumn(
            label: "Strain",
            fraction: 4.5 / 21,
            displayValue: 4.5,
            format: { String(format: "%.1f", $0) },
            accent: StrandPalette.effortColor
        )
    }
    .padding()
    .background(StrandPalette.surfaceBase)
}
#endif
