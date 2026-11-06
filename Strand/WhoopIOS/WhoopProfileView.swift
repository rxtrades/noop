#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP Profile (Mobbin 136): green gradient, avatar, PEAK chip, member since, level, streak, achievements.
struct WhoopProfileView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var repo: Repository
    @AppStorage("noop.displayName") private var displayName = ""

    private var name: String {
        let t = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Athlete" : t
    }

    private var recoveryCount: Int {
        repo.days.filter { ($0.recovery ?? 0) > 0 }.count
    }

    private var streakDays: Int {
        // Best-effort consecutive recovery days from newest.
        var n = 0
        for d in repo.days.sorted(by: { $0.day > $1.day }) {
            if (d.recovery ?? 0) > 0 { n += 1 } else { break }
        }
        return n
    }

    private var level: Int {
        max(1, recoveryCount / 80)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                VStack(alignment: .leading, spacing: 14) {
                    levelCard
                    streakCard
                    achievements
                    dataHighlights
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
        }
        .background(WhoopIOSDesign.bgBottom.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PROFILE")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.3)
                    .foregroundStyle(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "#0E4A36"), Color(hex: "#0A2E26"), Color(hex: "#0B1214"), WhoopIOSDesign.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 280)
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1A4A3A"), Color(hex: "#0E1C18")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text(name)
                    .font(WhoopType.title(26))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text("PEAK")
                        .font(WhoopType.labelCaps(10))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(WhoopIOSDesign.surfaceList))
                    Text("Whoople member")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }

                HStack(spacing: 8) {
                    WhoopleMark(size: 16)
                    Text("Member since joining Whoople")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(WhoopIOSDesign.surfaceList.opacity(0.9)))
                .padding(.bottom, 18)
            }
        }
    }

    private var levelCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [WhoopIOSDesign.strainBlue, WhoopIOSDesign.recoveryGreen, WhoopIOSDesign.strainBlue],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 54, height: 54)
                Text("\(level)")
                    .font(WhoopType.metric(22))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("LEVEL \(level)")
                    .font(WhoopType.rowCaps(14))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Text("\(recoveryCount) Recoveries")
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
    }

    private var streakCard: some View {
        HStack {
            Text("DAY STREAK")
                .font(WhoopType.rowCaps(13))
                .tracking(0.8)
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(WhoopIOSDesign.streakFlame)
                Text("\(streakDays) Days")
                    .font(WhoopType.cardTitle(15))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(WhoopType.cardTitle(17))
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    badge("figure.walk", "Walk", "500", .yellow)
                    badge("bolt.heart.fill", "Recovery", "\(max(recoveryCount, 1))", WhoopIOSDesign.recoveryGreen)
                    badge("moon.fill", "Sleep", "800", WhoopIOSDesign.strainBlue)
                    badge("flame.fill", "Strain", "300", WhoopIOSDesign.streakFlame)
                }
            }
        }
        .padding(.top, 6)
    }

    private func badge(_ icon: String, _ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.7), lineWidth: 2)
                    .frame(width: 64, height: 64)
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                    Text(value)
                        .font(WhoopType.caption(10))
                        .foregroundStyle(.white)
                }
            }
            Text(title)
                .font(WhoopType.caption(11))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
        .frame(width: 76)
    }

    private var dataHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Highlights")
                .font(WhoopType.cardTitle(17))
                .foregroundStyle(.white)
            WhoopCard {
                VStack(alignment: .leading, spacing: 10) {
                    highlightRow("Best Recovery", repo.days.compactMap(\.recovery).max().map { "\(Int($0.rounded()))%" } ?? "—")
                    highlightRow("Peak Strain", repo.days.compactMap(\.strain).max().map { String(format: "%.1f", $0) } ?? "—")
                    highlightRow("Longest Sleep", "—")
                }
            }
        }
        .padding(.top, 8)
    }

    private func highlightRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(WhoopType.body(14))
                .foregroundStyle(WhoopIOSDesign.textBody)
            Spacer()
            Text(value)
                .font(WhoopType.cardTitle(15))
                .foregroundStyle(.white)
        }
    }
}

#endif
