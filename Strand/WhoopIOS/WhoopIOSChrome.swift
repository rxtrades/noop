#if os(iOS)
import SwiftUI
import UIKit
import StrandDesign

struct WhoopCard<Content: View>: View {
    var raised: Bool = false
    var content: () -> Content

    init(raised: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.raised = raised
        self.content = content
    }

    var body: some View {
        content()
            .padding(WhoopIOSDesign.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(raised ? WhoopIOSDesign.cardRaised : WhoopIOSDesign.card)
            )
    }
}

struct WhoopSectionHeader: View {
    var title: LocalizedStringKey
    var showsChevron: Bool

    init(_ title: LocalizedStringKey, showsChevron: Bool = true) {
        self.title = title
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(WhoopType.rowCaps())
                .tracking(WhoopType.rowTracking)
                .textCase(.uppercase)
                .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }
}

/// Profile+streak pill · date with outer chevrons · battery + strap glyph (Mobbin header).
struct WhoopHomeHeader: View {
    var dayLabel: String
    var streakDays: Int
    var onPreviousDay: () -> Void
    var onNextDay: Bool
    var onNextDayTap: () -> Void
    var batteryPct: Int?
    var connected: Bool
    var onProfileTap: () -> Void = {}
    var onDeviceTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                HStack(spacing: 10) {
                    profileStreakPill
                    Spacer(minLength: 0)
                    deviceCluster
                }
                dateCluster
            }
            WhoopleWordmark(size: 18)
                .padding(.top, 2)
        }
    }

    /// Avatar joined with flame streak in one dark pill.
    private var profileStreakPill: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.streakFlame)
                Text("\(max(streakDays, 0))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(Capsule(style: .continuous).fill(WhoopIOSDesign.cardRaised))
        }
        .buttonStyle(.plain)
        .opacity(streakDays > 0 ? 1 : 0.85)
    }

    /// Chevrons OUTSIDE the date pill (GAP §0).
    private var dateCluster: some View {
        HStack(spacing: 6) {
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Text(dayLabel)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule(style: .continuous).fill(WhoopIOSDesign.cardRaised))

            Button(action: onNextDayTap) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!onNextDay)
            .opacity(onNextDay ? 1 : 0.35)
        }
    }

    private var deviceCluster: some View {
        Button(action: onDeviceTap) {
            HStack(spacing: 6) {
                if let batteryPct {
                    Text("\(batteryPct)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(batteryPct <= 15 ? WhoopIOSDesign.recoveryRed : WhoopIOSDesign.textSecondary)
                        .monospacedDigit()
                }
                ZStack(alignment: .bottomTrailing) {
                    // Minimal strap glyph (vertical capsule).
                    Capsule(style: .continuous)
                        .stroke(WhoopIOSDesign.textSecondary, lineWidth: 1.4)
                        .frame(width: 9, height: 16)
                    Circle()
                        .fill(connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textTertiary)
                        .frame(width: 6, height: 6)
                        .offset(x: 4, y: 2)
                }
                .frame(width: 18, height: 18)
            }
        }
        .buttonStyle(.plain)
    }
}

enum WhoopIOSTabBarAppearance {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(WhoopIOSDesign.tabBarFill)
        appearance.shadowColor = .clear
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(WhoopIOSDesign.textSecondary)
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

enum WhoopTrendDirection {
    case upGood, upBad, downGood, downBad, flat

    var systemImage: String {
        switch self {
        case .upGood, .upBad: return "arrow.up"
        case .downGood, .downBad: return "arrow.down"
        case .flat: return "circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .upGood, .downGood: return WhoopIOSDesign.trendUp
        case .upBad, .downBad: return WhoopIOSDesign.trendDown
        case .flat: return WhoopIOSDesign.textTertiary
        }
    }
}

struct WhoopStatusBanner: View {
    var icon: String
    var tint: Color
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WhoopType.cardTitle(15))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(WhoopType.caption())
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.cardRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

struct WhoopDashboardMetricRow: View {
    var icon: String
    var title: String
    var value: String
    var baseline: String?
    var trend: WhoopTrendDirection

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(WhoopType.rowCaps(12))
                    .tracking(WhoopType.rowTracking)
                    .foregroundStyle(WhoopIOSDesign.textPrimary.opacity(0.92))
                if let baseline {
                    Text(baseline)
                        .font(WhoopType.caption())
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                Text(value)
                    .font(WhoopType.metric(17))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Image(systemName: trend.systemImage)
                    .font(.system(size: trend == .flat ? 5 : 11, weight: .bold))
                    .foregroundStyle(trend.tint)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: WhoopIOSDesign.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

struct WhoopSparkline: View {
    var values: [Double]
    var tint: Color
    var fill: Color

    var body: some View {
        GeometryReader { geo in
            let vals = values.isEmpty ? [0.0] : values
            let maxV = max(vals.max() ?? 1, 0.001)
            let minV = min(vals.min() ?? 0, maxV - 0.001)
            let span = max(maxV - minV, 0.001)
            let step = geo.size.width / CGFloat(max(vals.count - 1, 1))

            Path { path in
                for (i, v) in vals.enumerated() {
                    let x = CGFloat(i) * step
                    let y = geo.size.height - CGFloat((v - minV) / span) * geo.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            Path { path in
                for (i, v) in vals.enumerated() {
                    let x = CGFloat(i) * step
                    let y = geo.size.height - CGFloat((v - minV) / span) * geo.size.height
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(fill)
        }
    }
}

struct WhoopDualSparkline: View {
    var primary: [Double]
    var secondary: [Double]
    var primaryTint: Color
    var secondaryTint: Color

    var body: some View {
        ZStack {
            WhoopSparkline(values: secondary, tint: secondaryTint, fill: secondaryTint.opacity(0.10))
            WhoopSparkline(values: primary, tint: primaryTint, fill: .clear)
        }
    }
}

#endif
