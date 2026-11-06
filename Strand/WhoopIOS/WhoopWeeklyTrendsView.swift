#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP Weekly Trends (Mobbin 080): Recovery bars + HRV line + RHR, each linking to Trend View.
struct WhoopWeeklyTrendsView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal

    @State private var weekOffset = 0

    private var weekDays: [DailyMetric] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Align to week containing today - offset, Mon-first labels like Mobbin
        let anchor = cal.date(byAdding: .day, value: -7 * weekOffset, to: today) ?? today
        let weekday = cal.component(.weekday, from: anchor) // 1=Sun
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday - (weekOffset == 0 ? 0 : 0), to: anchor)
            ?? anchor
        // For offset weeks, recompute monday of that week:
        let weekStart: Date = {
            let base = cal.date(byAdding: .day, value: -7 * weekOffset, to: today) ?? today
            let wd = cal.component(.weekday, from: base)
            let fromMon = (wd + 5) % 7
            return cal.date(byAdding: .day, value: -fromMon, to: base) ?? base
        }()
        _ = monday
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let keys = (0..<7).compactMap { i -> String? in
            guard let d = cal.date(byAdding: .day, value: i, to: weekStart) else { return nil }
            return f.string(from: d)
        }
        let byDay = Dictionary(uniqueKeysWithValues: repo.days.map { ($0.day, $0) })
        return keys.map { key in
            byDay[key] ?? DailyMetric(
                day: key, totalSleepMin: nil, efficiency: nil, deepMin: nil, remMin: nil, lightMin: nil,
                disturbances: nil, restingHr: nil, avgHrv: nil, recovery: nil, strain: nil, exerciseCount: nil
            )
        }
    }

    private var rangeLabel: String {
        if weekOffset == 0 { return "THIS WEEK TO TODAY" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        guard let first = weekDays.first.flatMap({ date(from: $0.day) }),
              let last = weekDays.last.flatMap({ date(from: $0.day) }) else {
            return "WEEK"
        }
        return "\(f.string(from: first).uppercased()) – \(f.string(from: last).uppercased())"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Color.clear.frame(height: 1).id("whoopWeeklyTop")
                    HStack {
                        Text("Weekly Trends")
                            .font(WhoopType.title(28))
                            .foregroundStyle(.white)
                        Spacer()
                        HStack(spacing: 10) {
                            Button { weekOffset += 1 } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            Button {
                                weekOffset = max(0, weekOffset - 1)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(weekOffset == 0)
                            .opacity(weekOffset == 0 ? 0.35 : 1)
                        }
                    }

                    Text(rangeLabel)
                        .font(WhoopType.labelCaps(12))
                        .tracking(0.8)
                        .foregroundStyle(WhoopIOSDesign.textSecondary)

                    NavigationLink(value: TabRoute.whoopTrend("recovery")) {
                        WhoopWeeklyBarCard(
                            title: "RECOVERY",
                            days: weekDays,
                            values: weekDays.map { $0.recovery },
                            highlightLast: weekOffset == 0,
                            colorFor: { WhoopIOSDesign.recoveryAccent(score: $0) },
                            format: { "\(Int($0.rounded()))" }
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: TabRoute.whoopTrend("hrv")) {
                        WhoopWeeklyLineCard(
                            title: "HEART RATE VARIABILITY",
                            days: weekDays,
                            values: weekDays.map { $0.avgHrv },
                            highlightLast: weekOffset == 0,
                            lineColor: WhoopIOSDesign.sleepBlue,
                            format: { String(format: "%.0f", $0) }
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: TabRoute.whoopTrend("rhr")) {
                        WhoopWeeklyLineCard(
                            title: "RESTING HEART RATE",
                            days: weekDays,
                            values: weekDays.map { $0.restingHr.map(Double.init) },
                            highlightLast: weekOffset == 0,
                            lineColor: Color(hex: "#FF6B6B"),
                            format: { "\(Int($0.rounded()))" }
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: TabRoute.whoopTrend("strain")) {
                        WhoopWeeklyBarCard(
                            title: "STRAIN",
                            days: weekDays,
                            values: weekDays.map { $0.strain },
                            highlightLast: weekOffset == 0,
                            colorFor: { _ in WhoopIOSDesign.strainBlue },
                            format: { String(format: "%.1f", $0) }
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: TabRoute.whoopTrend("sleep_performance")) {
                        WhoopWeeklyBarCard(
                            title: "SLEEP PERFORMANCE",
                            days: weekDays,
                            values: weekDays.map { d in
                                if let e = d.efficiency { return e <= 1.5 ? e * 100 : e }
                                guard let asleep = d.totalSleepMin else { return nil }
                                return min(100, (asleep / 480) * 100)
                            },
                            highlightLast: weekOffset == 0,
                            colorFor: { _ in WhoopIOSDesign.sleepBlue },
                            format: { "\(Int($0.rounded()))" }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 8)
                .padding(.bottom, 110)
            }
            .whoopPageBackground()
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo("whoopWeeklyTop", anchor: .top)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func date(from key: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: key)
    }
}

struct WhoopWeeklyBarCard: View {
    var title: String
    var days: [DailyMetric]
    var values: [Double?]
    var highlightLast: Bool
    var colorFor: (Double) -> Color
    var format: (Double) -> String

    var body: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 12) {
                WhoopSectionHeader(LocalizedStringKey(title), showsChevron: true)
                GeometryReader { geo in
                    let n = max(values.count, 1)
                    let slot = geo.size.width / CGFloat(n)
                    let maxV = max(values.compactMap { $0 }.max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                            let isLast = i == values.count - 1
                            VStack(spacing: 4) {
                                if let v {
                                    Text(format(v))
                                        .font(WhoopType.caption(9))
                                        .foregroundStyle(colorFor(v))
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                } else {
                                    Text(" ")
                                        .font(WhoopType.caption(9))
                                }
                                ZStack(alignment: .bottom) {
                                    if highlightLast && isLast {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(WhoopIOSDesign.surfaceList.opacity(0.55))
                                            .frame(width: slot * 0.72, height: geo.size.height - 36)
                                    }
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(v.map(colorFor) ?? WhoopIOSDesign.ringTrack)
                                        .frame(
                                            width: slot * 0.45,
                                            height: max(4, CGFloat((v ?? 0) / maxV) * (geo.size.height - 52))
                                        )
                                }
                                .frame(height: geo.size.height - 36, alignment: .bottom)
                                Text(dayLabel(days[safe: i]?.day))
                                    .font(WhoopType.caption(9))
                                    .foregroundStyle(isLast && highlightLast ? .white : WhoopIOSDesign.textSecondary)
                            }
                            .frame(width: slot)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private func dayLabel(_ key: String?) -> String {
        guard let key else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return "" }
        let out = DateFormatter()
        out.dateFormat = "EEE d"
        return out.string(from: d)
    }
}

struct WhoopWeeklyLineCard: View {
    var title: String
    var days: [DailyMetric]
    var values: [Double?]
    var highlightLast: Bool
    var lineColor: Color
    var format: (Double) -> String

    var body: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 12) {
                WhoopSectionHeader(LocalizedStringKey(title), showsChevron: true)
                GeometryReader { geo in
                    let pts = values.enumerated().compactMap { i, v -> (Int, Double)? in
                        guard let v else { return nil }
                        return (i, v)
                    }
                    let w = geo.size.width
                    let h = geo.size.height - 24
                    let n = max(values.count, 2)
                    let lo = (pts.map(\.1).min() ?? 0) - 5
                    let hi = (pts.map(\.1).max() ?? 1) + 5
                    let span = max(hi - lo, 1)

                    ZStack {
                        if highlightLast {
                            let x = w * CGFloat(n - 1) / CGFloat(n - 1)
                            Rectangle()
                                .fill(WhoopIOSDesign.surfaceList.opacity(0.45))
                                .frame(width: w / CGFloat(n) * 0.7, height: h)
                                .position(x: x - (w / CGFloat(n) * 0.15), y: h / 2)
                        }
                        if pts.count >= 2 {
                            Path { path in
                                for (j, pair) in pts.enumerated() {
                                    let x = w * CGFloat(pair.0) / CGFloat(n - 1)
                                    let y = h * (1 - CGFloat((pair.1 - lo) / span))
                                    if j == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                            ForEach(Array(pts.enumerated()), id: \.offset) { _, pair in
                                let x = w * CGFloat(pair.0) / CGFloat(n - 1)
                                let y = h * (1 - CGFloat((pair.1 - lo) / span))
                                Circle()
                                    .fill(lineColor)
                                    .frame(width: 7, height: 7)
                                    .position(x: x, y: y)
                                Text(format(pair.1))
                                    .font(WhoopType.caption(9))
                                    .foregroundStyle(lineColor)
                                    .position(x: x, y: max(8, y - 12))
                            }
                        }
                    }
                    .frame(height: h)

                    HStack(spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                            Text(dayLabel(d.day))
                                .font(WhoopType.caption(9))
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private func dayLabel(_ key: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: key) else { return "" }
        let out = DateFormatter()
        out.dateFormat = "EEE d"
        return out.string(from: d)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#endif
