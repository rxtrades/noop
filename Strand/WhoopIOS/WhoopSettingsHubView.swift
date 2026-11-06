#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP Settings hub (Mobbin 123/125/126): carousel · Refer & Earn · Gift · Account & Settings · Support · Logout.
struct WhoopSettingsHubView: View {
    var showsClose: Bool = false
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState

    @State private var carouselPage = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                membershipCarousel
                referEarn
                section("GIFT") {
                    settingsRow(icon: "gift", title: "GIFT A MEMBERSHIP",
                                subtitle: "Gift a new member or purchase a gift card")
                }

                section("ACCOUNT & SETTINGS") {
                    NavigationLink {
                        WhoopProfileView()
                    } label: {
                        settingsRow(icon: "person.crop.circle", title: "MY ACCOUNT")
                    }
                    .buttonStyle(.plain)

                    settingsRow(icon: "flask", title: "DIGITAL WHOOPLE LABS")

                    NavigationLink {
                        WhoopDeviceSettingsView(device: nil)
                    } label: {
                        settingsRow(icon: "applewatch.watchface", title: "DEVICE SETTINGS")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WhoopAppSettingsView()
                    } label: {
                        settingsRow(icon: "list.clipboard", title: "APP SETTINGS")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WhoopPrivacySettingsView()
                    } label: {
                        settingsRow(icon: "eye", title: "PRIVACY SETTINGS")
                    }
                    .buttonStyle(.plain)
                }

                section("SUPPORT") {
                    settingsRow(icon: "headphones", title: "MEMBERSHIP SERVICES",
                                subtitle: "Get help or ask a question")
                    settingsRow(icon: "graduationcap", title: "TUTORIALS")
                    settingsRow(icon: "w.circle", title: "ABOUT")
                    settingsRow(icon: "tag", title: "REGULATORY LABELS")
                    settingsRow(icon: "graduationcap", title: "FIRST WEEK WITH WHOOPLE")
                }

                Button {
                    onClose?() ?? dismiss()
                } label: {
                    Text("LOGOUT")
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)

                Text("APP VERSION: \(appVersionLabel)")
                    .font(WhoopType.caption(11))
                    .tracking(0.6)
                    .foregroundStyle(WhoopIOSDesign.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.top, 8)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.4)
                    .foregroundStyle(.white)
            }
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onClose?() ?? dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.96), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var appVersionLabel: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (BUILD \(b))"
    }

    private var membershipCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $carouselPage) {
                promoCard(
                    title: "EXTEND MEMBERSHIP",
                    body: "Save up to 16% per month by purchasing an extended pre-paid period.",
                    tag: 0
                )
                promoCard(
                    title: "WHOOPLE BASICS",
                    body: "Recovery, Strain, and Sleep — how the three pillars work together.",
                    tag: 1
                )
                promoCard(
                    title: "PAIR YOUR STRAP",
                    body: "Connect a band to unlock overnight recovery and daytime strain.",
                    tag: 2
                )
                promoCard(
                    title: "COACH",
                    body: "Bring your own API key under App Settings › AI Settings.",
                    tag: 3
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 168)

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i == carouselPage ? Color.white : Color.white.opacity(0.28))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }

    private func promoCard(title: String, body: String, tag: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A3A32"), Color(hex: "#12181C"), Color(hex: "#0C1014")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(WhoopType.labelCaps(15))
                    .tracking(1)
                    .foregroundStyle(.white)
                Text(body)
                    .font(WhoopType.body(13))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(18)
        }
        .tag(tag)
        .padding(.horizontal, 1)
    }

    private var referEarn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REFER & EARN")
                .font(WhoopType.rowCaps(12))
                .tracking(1)
                .foregroundStyle(WhoopIOSDesign.textSecondary)

            HStack(spacing: 14) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("GET ONE MONTH FREE")
                        .font(WhoopType.rowCaps(13))
                        .tracking(0.7)
                        .foregroundStyle(.white)
                    Text("When you refer, you and a friend will get one month free.")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2A3A36"), Color(hex: "#2B2836"), Color(hex: "#243038")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
            )

            HStack(spacing: 14) {
                Image(systemName: "megaphone")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHARE A FREE TRIAL")
                        .font(WhoopType.rowCaps(13))
                        .tracking(0.7)
                        .foregroundStyle(.white)
                    Text("Invite your community to experience Whoople.")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                            .fill(WhoopIOSDesign.surfaceList)
                    )
            )
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(WhoopType.rowCaps(12))
                .tracking(1)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            VStack(spacing: 8) { content() }
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(WhoopType.rowCaps(14))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
        .contentShape(Rectangle())
    }
}

/// Lightweight privacy surface (Whoople-branded).
struct WhoopPrivacySettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your metrics stay on this device unless you explicitly export or ask Coach (your own API key).")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                WhoopCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ON-DEVICE FIRST")
                            .font(WhoopType.rowCaps(12))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        Text("No Whoople cloud account is required for core recovery, strain, and sleep.")
                            .font(WhoopType.body(14))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(WhoopIOSDesign.pageMargin)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PRIVACY SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.2)
                    .foregroundStyle(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#endif
