#if os(iOS)
import SwiftUI
import UIKit
import StrandDesign

// MARK: - Shared WHOOP-inspired chrome (iOS only)

enum WhoopIOSColors {
    static let sleepAccent = Color(hex: "#6FA8E8")
    static let cardFill = Color(hex: "#1C1C1E")
    static let cardBorder = Color(hex: "#2C2C2E")
}

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
                    .fill(WhoopIOSColors.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: NoopVisualStyle.cardRadius, style: .continuous)
                            .strokeBorder(WhoopIOSColors.cardBorder, lineWidth: 0.5)
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
                .font(StrandFont.overline)
                .tracking(StrandFont.overlineTracking)
                .textCase(.uppercase)
                .foregroundStyle(StrandPalette.textPrimary)
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
        }
    }
}

/// Date pill + centred NOOP wordmark + strap battery (WHOOP home header pattern).
struct WhoopHomeHeader: View {
    var dayLabel: String
    var onPreviousDay: () -> Void
    var onNextDay: Bool
    var onNextDayTap: () -> Void
    var batteryPct: Int?
    var connected: Bool
    var onProfileTap: () -> Void = {}
    var onDeviceTap: () -> Void = {}

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                Button(action: onProfileTap) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(StrandPalette.textSecondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile and settings")
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Button(action: onPreviousDay) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(StrandPalette.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    Text(dayLabel)
                        .font(StrandFont.overline)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(StrandPalette.textPrimary)
                        .padding(.horizontal, 6)
                    Button(action: onNextDayTap) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(onNextDay ? StrandPalette.textSecondary : StrandPalette.textTertiary.opacity(0.35))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(!onNextDay)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(StrandPalette.surfaceRaised.opacity(0.85))
                )
                Spacer(minLength: 0)
                Button(action: onDeviceTap) {
                    HStack(spacing: 6) {
                        if let batteryPct {
                            Text("\(batteryPct)%")
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.textSecondary)
                                .monospacedDigit()
                        }
                        Image(systemName: connected ? "applewatch" : "applewatch.slash")
                            .font(.system(size: 16))
                            .foregroundStyle(connected ? StrandPalette.statusPositive : StrandPalette.textTertiary)
                    }
                    .padding(.horizontal, 4)
                    .frame(minHeight: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(connected ? "Devices, connected" : "Devices, not connected")
            }
            Text("NOOP")
                .font(.system(size: 22, weight: .bold, design: .default))
                .tracking(6)
                .foregroundStyle(StrandPalette.textPrimary)
        }
    }
}

/// Applies UIKit tab-bar styling to match WHOOP's dark floating pill (best-effort on system TabView).
enum WhoopIOSTabBarAppearance {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        appearance.shadowColor = .clear
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.55, alpha: 1)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.55, alpha: 1),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.55, alpha: 1)
    }
}

#endif
