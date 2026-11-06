#if os(iOS)
import SwiftUI
import StrandDesign

/// Activity detail with WHOOP zone bar colors (Mobbin activity detail).
struct WhoopActivityDetailView: View {
    var sport: String
    var strain: Double?
    var avgHr: Int?
    var peakHr: Int?
    var calories: Int?
    var durationS: Double?
    var zoneMinutes: [Int]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: sportSymbol(sport))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(WhoopIOSDesign.strainBlue)
                    Text(sport.uppercased())
                        .font(WhoopType.title(22))
                        .foregroundStyle(.white)
                    Spacer()
                }

                HStack(spacing: 10) {
                    statTile("STRAIN", strain.map { String(format: "%.1f", $0) } ?? "—")
                    statTile("AVG HR", avgHr.map { "\($0)" } ?? "—")
                    statTile("PEAK HR", peakHr.map { "\($0)" } ?? "—")
                }

                HStack(spacing: 10) {
                    statTile("DURATION", durationLabel)
                    statTile("CALORIES", calories.map { "\($0)" } ?? "—")
                }

                WhoopCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("HEART RATE ZONES")
                            .font(WhoopType.rowCaps(12))
                            .tracking(0.8)
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        ForEach(1...5, id: \.self) { z in
                            zoneRow(z, minutes: zoneMinutes.flatMap { $0.indices.contains(z - 1) ? $0[z - 1] : nil })
                        }
                    }
                }

                WhoopCoachCard(message: String(localized: "Nice work. Review strain and sleep tonight to lock in the adaptation from this activity."))
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var durationLabel: String {
        guard let durationS else { return "—" }
        let s = Int(durationS)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func statTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(WhoopType.caption(10))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Text(value)
                .font(WhoopType.metric(24))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }

    private func zoneRow(_ zone: Int, minutes: Int?) -> some View {
        HStack(spacing: 12) {
            Text("Z\(zone)")
                .font(WhoopType.labelCaps(12))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .leading)
            GeometryReader { geo in
                let frac = min(1, Double(minutes ?? 0) / 30.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(WhoopIOSDesign.ringTrack)
                    Capsule().fill(Self.zoneColor(zone))
                        .frame(width: max(4, geo.size.width * frac))
                }
            }
            .frame(height: 10)
            Text(minutes.map { formatMin($0) } ?? "0:00")
                .font(WhoopType.caption(12))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func formatMin(_ m: Int) -> String {
        String(format: "%d:%02d", m / 60, m % 60)
    }

    static func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Color(hex: "#6B7280")
        case 2: return WhoopIOSDesign.strainBlue // #0093E7
        case 3: return WhoopIOSDesign.recoveryGreen // #16EC06
        case 4: return Color(hex: "#FFB74D")
        default: return Color(hex: "#FF7A00")
        }
    }
}

#endif
