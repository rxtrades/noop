#if os(iOS)
import SwiftUI
import UIKit
import StrandDesign

struct WhoopCard<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(NoopVisualStyle.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NoopVisualStyle.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: NoopVisualStyle.cardRadius, style: .continuous)
                            .strokeBorder(WhoopIOSDesign.cardBorder, lineWidth: 0.5)
                    )
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
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundStyle(StrandPalette.textPrimary)
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }
}

/// Profile · streak · TODAY pill · battery + device (WHOOP home header).
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
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: onProfileTap) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .buttonStyle(.plain)
                if streakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(WhoopIOSDesign.streakFlame)
                            .shadow(color: WhoopIOSDesign.streakFlame.opacity(0.6), radius: 4)
                        Text("\(streakDays)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
                datePill
                Spacer(minLength: 0)
                deviceCluster
            }
            WhoopleWordmark(size: 21)
        }
    }

    private var datePill: some View {
        HStack(spacing: 0) {
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            Text(dayLabel)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            Button(action: onNextDayTap) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(!onNextDay)
            .opacity(onNextDay ? 1 : 0.35)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(WhoopIOSDesign.cardElevated))
    }

    private var deviceCluster: some View {
        Button(action: onDeviceTap) {
            HStack(spacing: 5) {
                if let batteryPct {
                    Text("\(batteryPct)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(batteryPct <= 15 ? Color.red : WhoopIOSDesign.textSecondary)
                        .monospacedDigit()
                }
                Image(systemName: connected ? "applewatch" : "applewatch.slash")
                    .font(.system(size: 15))
                    .foregroundStyle(connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

enum WhoopIOSTabBarAppearance {
    /// Legacy UIKit tint when the system tab bar is visible (Whoople home off).
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        appearance.shadowColor = .clear
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#endif
