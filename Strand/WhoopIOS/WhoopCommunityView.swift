#if os(iOS)
import SwiftUI
import StrandDesign

/// Community tab — WHOOP-style empty state (Mobbin “Build Your Community”).
/// Teams/leaderboards land in a later phase; this replaces the accidental Sleep routing.
struct WhoopCommunityView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Community")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                // Hero empty state matching WHOOP “Build Your Community”
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#3D4A55"),
                                        WhoopIOSDesign.card
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    .padding(.top, 28)

                    Text("Build Your Community")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Invite friends and family to share Recovery, Strain, and Sleep — coming soon to \(WhoopleBranding.displayName).")
                        .font(.system(size: 15))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    Button(action: {}) {
                        Text("Create Family Plan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .disabled(true)
                    .opacity(0.55)

                    Button(action: {}) {
                        Text("Refer a Friend")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [WhoopIOSDesign.cardRaised, WhoopIOSDesign.card],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )

                communityRow(icon: "person.badge.plus", title: "Invite to \(WhoopleBranding.displayName)",
                             subtitle: "Share a link once teams ship")
                communityRow(icon: "trophy", title: "Team Leaderboards",
                             subtitle: "Recovery · Strain · Sleep rankings")
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.bottom, 120)
        }
        .whoopPageBackground()
    }

    private func communityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WhoopIOSDesign.textTertiary)
        }
        .padding(.horizontal, WhoopIOSDesign.pageMargin)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

#endif
