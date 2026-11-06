#if os(iOS)
import SwiftUI
import StrandDesign

/// Community tab — WHOOP-style empty state (Mobbin 028): Build Your Community + Teams.
struct WhoopCommunityView: View {
    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Build Your Community")
                    .font(WhoopType.title(26))
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                    .whoopCardAppear(index: 0, visible: appear)

                // CREATE FAMILY PLAN — iridescent gradient card
                HStack(spacing: 14) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CREATE FAMILY PLAN")
                            .font(WhoopType.rowCaps(13))
                            .tracking(0.7)
                            .foregroundStyle(.white)
                        Text("Save big with 2–6 members on one bill.")
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
                .whoopCardAppear(index: 1, visible: appear)

                // REFER A FRIEND — outlined card
                HStack(spacing: 14) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REFER A FRIEND")
                            .font(WhoopType.rowCaps(13))
                            .tracking(0.7)
                            .foregroundStyle(.white)
                        Text("Get 1 month credit for each friend you refer.")
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
                .whoopCardAppear(index: 2, visible: appear)

                HStack {
                    Text("Teams")
                        .font(WhoopType.cardTitle(18))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .padding(.top, 6)
                .whoopCardAppear(index: 3, visible: appear)

                Text("GETTING STARTED")
                    .font(WhoopType.rowCaps(12))
                    .tracking(1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .whoopCardAppear(index: 4, visible: appear)

                communityRow(icon: "person.3", title: "Enter Invite Code",
                             subtitle: "Join a team with a code")
                    .whoopCardAppear(index: 5, visible: appear)
                communityRow(icon: "plus.circle", title: "Create Team",
                             subtitle: "Start a Recovery · Strain · Sleep leaderboard")
                    .whoopCardAppear(index: 6, visible: appear)

                HStack {
                    Text("RECOMMENDED TEAMS")
                        .font(WhoopType.rowCaps(12))
                        .tracking(1)
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                    Spacer()
                    Text("VIEW ALL")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
                .whoopCardAppear(index: 7, visible: appear)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        teamCard(title: "WHOOPLE RUNNERS", members: "Coming soon", tint: WhoopIOSDesign.strainBlue)
                        teamCard(title: "RECOVERY CLUB", members: "Coming soon", tint: WhoopIOSDesign.recoveryGreen)
                        teamCard(title: "SLEEP SQUAD", members: "Coming soon", tint: WhoopIOSDesign.sleepBlue)
                    }
                }
                .whoopCardAppear(index: 8, visible: appear)
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.bottom, 120)
        }
        .whoopPageBackground()
        .onAppear {
            withAnimation(WhoopIOSDesign.cardAppear) { appear = true }
        }
    }

    private func communityRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(WhoopType.cardTitle(16))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(WhoopType.caption(12))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
    }

    private func teamCard(title: String, members: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.45), WhoopIOSDesign.card],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 90)
                Circle()
                    .fill(tint.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    )
            }
            Text(title)
                .font(WhoopType.rowCaps(12))
                .tracking(0.6)
                .foregroundStyle(.white)
            Text(members)
                .font(WhoopType.caption(11))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
        .frame(width: 148)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

#endif
