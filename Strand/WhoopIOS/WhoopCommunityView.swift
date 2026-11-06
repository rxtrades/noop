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
                                        Color(hex: "#1F2427")
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
                        .foregroundStyle(Color(hex: "#8A9399"))
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
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#2B2F32"), Color(hex: "#1F2427")],
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
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func communityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "#8A9399"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#8A9399"))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#5E676D"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "#1F2427"))
        )
    }
}

#endif
