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

#endif
