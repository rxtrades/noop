#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP-style Trend View (Mobbin 076/050): metric dropdown, average + delta, W/M/6M, band line chart.
struct WhoopTrendView: View {
    var metricKey: String

    @EnvironmentObject private var repo: Repository
    @State private var selectedKey: String = ""
    @State private var period: Period = .month
    @State private var offset: Int = 0 // 0 = current window ending today; +1 = one window back
    @State private var showPicker = false

    enum Period: String, CaseIterable, Identifiable {
        case week = "W", month = "M", sixMonth = "6M"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .sixMonth: return 180
            }
        }
        var priorLabel: String {
            switch self {
            case .week: return String(localized: "vs. prior week")
            case .month: return String(localized: "vs. prior month")
            case .sixMonth: return String(localized: "vs. prior 6 months")
            }
        }
    }

    private var key: String { selectedKey.isEmpty ? metricKey : selectedKey }
    private var metric: WhoopTrendMetric { WhoopTrendMetric.catalog.first(where: { $0.key == key }) ?? WhoopTrendMetric.catalog[0] }

    private var window: [WhoopTrendPoint] {
        WhoopTrendMetric.points(for: metric, days: repo.days, periodDays: period.days, offset: offset)
    }

    private var priorWindow: [WhoopTrendPoint] {
        WhoopTrendMetric.points(for: metric, days: repo.days, periodDays: period.days, offset: offset + 1)
    }

    private var average: Double? {
        let vals = window.map(\.value)
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    private var priorAverage: Double? {
        let vals = priorWindow.map(\.value)
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    private var deltaPct: Double? {
        guard let average, let priorAverage, priorAverage != 0 else { return nil }
        return ((average - priorAverage) / abs(priorAverage)) * 100
    }

    private var band: (low: Double, high: Double)? {
        let vals = window.map(\.value).sorted()
        guard vals.count >= 3 else { return nil }
        let lo = vals[max(0, vals.count / 4)]
        let hi = vals[min(vals.count - 1, (vals.count * 3) / 4)]
        return (lo, hi)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                metricDropdown
                summaryRow
                dateRangeRow
                insightText
                legendRow
                WhoopBandLineChart(
                    points: window,
                    band: band,
                    lineColor: metric.lineColor,
                    valueFormat: metric.format
                )
                .frame(height: 220)
                .padding(.top, 4)

                WhoopCard {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(WhoopIOSDesign.strainBlue)
                        Text(String(localized: "Typical range is the middle 50% of values in this window. Tap the metric name to compare another signal."))
                            .font(WhoopType.body(13))
                            .foregroundStyle(WhoopIOSDesign.textBody)
                    }
                }
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TREND VIEW")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.0)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { if selectedKey.isEmpty { selectedKey = metricKey } }
        .sheet(isPresented: $showPicker) {
            WhoopTrendMetricPicker(selectedKey: $selectedKey, isPresented: $showPicker)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var metricDropdown: some View {
        Button { showPicker = true } label: {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .frame(width: 28)
                Text(metric.title)
                    .font(WhoopType.rowCaps(13))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.card)
            )
        }
        .buttonStyle(.plain)
    }

    private var summaryRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AVERAGE")
                    .font(WhoopType.caption(11))
                    .tracking(1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(average.map { metric.format($0) } ?? "—")
                        .font(WhoopType.metric(34))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    if let unit = metric.unit, average != nil {
                        Text(unit)
                            .font(WhoopType.body(15))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                    }
                }
                if let deltaPct {
                    let up = deltaPct >= 0
                    let good = metric.higherIsBetter ? up : !up
                    Text("\(up ? "▲" : "▼") \(Int(abs(deltaPct).rounded()))% \(period.priorLabel)")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(good ? WhoopIOSDesign.trendUp : WhoopIOSDesign.trendDown)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill((good ? WhoopIOSDesign.trendUp : WhoopIOSDesign.trendDown).opacity(0.15))
                        )
                }
            }
            Spacer()
            periodControl
        }
    }

    private var periodControl: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases) { p in
                Button {
                    period = p
                    offset = 0
                } label: {
                    Text(p.rawValue)
                        .font(WhoopType.labelCaps(12))
                        .foregroundStyle(period == p ? .white : WhoopIOSDesign.textSecondary)
                        .frame(width: 40, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(period == p ? WhoopIOSDesign.surfaceList : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }

    private var dateRangeRow: some View {
        HStack {
            Button {
                offset += 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(dateRangeLabel)
                .font(WhoopType.labelCaps(12))
                .tracking(0.6)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Spacer()
            Button {
                offset = max(0, offset - 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .disabled(offset == 0)
            .opacity(offset == 0 ? 0.35 : 1)
        }
    }

    private var dateRangeLabel: String {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: -(offset * period.days), to: Date()) ?? Date()
        let start = cal.date(byAdding: .day, value: -(period.days - 1), to: end) ?? end
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let y = DateFormatter()
        y.dateFormat = "yy"
        return "\(f.string(from: start).uppercased()) – \(f.string(from: end).uppercased()), \(y.string(from: end))"
    }

    private var insightText: some View {
        Group {
            if let average, let priorAverage {
                Text(String(localized: "Your average \(metric.shortTitle) this period (\(metric.format(average))) was \(average >= priorAverage ? "above" : "below") your previous average of \(metric.format(priorAverage))."))
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textBody)
            } else {
                Text(String(localized: "Wear \(WhoopleBranding.displayName) to build a \(metric.shortTitle) trend."))
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2).fill(WhoopIOSDesign.rangeBand)
                    .frame(width: 16, height: 10)
                Text("TYPICAL RANGE")
                    .font(WhoopType.caption(10))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            HStack(spacing: 6) {
                Capsule().fill(metric.lineColor).frame(width: 16, height: 3)
                Text(metric.shortTitle.uppercased())
                    .font(WhoopType.caption(10))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer()
        }
    }
}

struct WhoopTrendPoint: Identifiable {
    var id: String { day }
    var day: String
    var value: Double
    var date: Date
}

struct WhoopTrendMetric: Identifiable {
    var id: String { key }
    var key: String
    var title: String
    var shortTitle: String
    var unit: String?
    var icon: String
    var higherIsBetter: Bool
    var lineColor: Color
    var format: (Double) -> String
    var extract: (DailyMetric) -> Double?

    static let catalog: [WhoopTrendMetric] = [
        WhoopTrendMetric(key: "recovery", title: "RECOVERY", shortTitle: "Recovery", unit: "%", icon: "heart.circle",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.recoveryGreen,
                         format: { "\(Int($0.rounded()))" }, extract: { $0.recovery }),
        WhoopTrendMetric(key: "hrv", title: "HEART RATE VARIABILITY", shortTitle: "HRV", unit: "ms", icon: "waveform.path.ecg",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.sleepBlue,
                         format: { String(format: "%.0f", $0) }, extract: { $0.avgHrv }),
        WhoopTrendMetric(key: "rhr", title: "RESTING HEART RATE", shortTitle: "RHR", unit: "bpm", icon: "heart.fill",
                         higherIsBetter: false, lineColor: Color(hex: "#FF6B6B"),
                         format: { "\(Int($0.rounded()))" }, extract: { $0.restingHr.map(Double.init) }),
        WhoopTrendMetric(key: "strain", title: "STRAIN", shortTitle: "Strain", unit: nil, icon: "flame",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.strainBlue,
                         format: { String(format: "%.1f", $0) }, extract: { $0.strain }),
        WhoopTrendMetric(key: "sleep_performance", title: "SLEEP PERFORMANCE", shortTitle: "Sleep", unit: "%", icon: "moon.fill",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.sleepBlue,
                         format: { "\(Int($0.rounded()))" },
                         extract: { d in
                             if let e = d.efficiency { return e <= 1.5 ? e * 100 : e }
                             guard let asleep = d.totalSleepMin else { return nil }
                             return min(100, (asleep / 480) * 100)
                         }),
        WhoopTrendMetric(key: "steps", title: "STEPS", shortTitle: "Steps", unit: nil, icon: "figure.walk",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.mint,
                         format: { NumberFormatter.localizedString(from: NSNumber(value: Int($0)), number: .decimal) },
                         extract: { $0.steps.map(Double.init) }),
        WhoopTrendMetric(key: "energy_kcal", title: "CALORIES", shortTitle: "Calories", unit: "kcal", icon: "flame.fill",
                         higherIsBetter: true, lineColor: WhoopIOSDesign.streakFlame,
                         format: { "\(Int($0.rounded()))" }, extract: { $0.activeKcalEst }),
        WhoopTrendMetric(key: "resp", title: "RESPIRATORY RATE", shortTitle: "Resp Rate", unit: "rpm", icon: "lungs.fill",
                         higherIsBetter: false, lineColor: WhoopIOSDesign.sleepBlue,
                         format: { String(format: "%.1f", $0) }, extract: { $0.respRateBpm }),
    ]

    static func points(for metric: WhoopTrendMetric, days: [DailyMetric], periodDays: Int, offset: Int) -> [WhoopTrendPoint] {
        let cal = Calendar.current
        let end = cal.date(byAdding: .day, value: -(offset * periodDays), to: cal.startOfDay(for: Date())) ?? Date()
        let start = cal.date(byAdding: .day, value: -(periodDays - 1), to: end) ?? end
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        let startKey = f.string(from: start)
        let endKey = f.string(from: end)
        return days
            .filter { $0.day >= startKey && $0.day <= endKey }
            .compactMap { d -> WhoopTrendPoint? in
                guard let v = metric.extract(d), let date = f.date(from: d.day) else { return nil }
                return WhoopTrendPoint(day: d.day, value: v, date: date)
            }
            .sorted { $0.day < $1.day }
    }
}

private struct WhoopTrendMetricPicker: View {
    @Binding var selectedKey: String
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(WhoopTrendMetric.catalog) { m in
                    Button {
                        selectedKey = m.key
                        isPresented = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: m.icon)
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                                .frame(width: 24)
                            Text(m.title)
                                .font(WhoopType.rowCaps(13))
                                .foregroundStyle(.white)
                            Spacer()
                            if m.key == selectedKey {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(WhoopIOSDesign.strainBlue)
                            }
                        }
                    }
                    .listRowBackground(WhoopIOSDesign.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(WhoopIOSDesign.bgBase.ignoresSafeArea())
            .navigationTitle("Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct WhoopBandLineChart: View {
    var points: [WhoopTrendPoint]
    var band: (low: Double, high: Double)?
    var lineColor: Color
    var valueFormat: (Double) -> String

    var body: some View {
        GeometryReader { geo in
            let vals = points.map(\.value)
            let dataMin = min(vals.min() ?? 0, band?.low ?? .infinity)
            let dataMax = max(vals.max() ?? 1, band?.high ?? -.infinity)
            let pad = max((dataMax - dataMin) * 0.15, 1)
            let lo = dataMin - pad
            let hi = dataMax + pad
            let span = max(hi - lo, 1)
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                // grid
                ForEach(0..<5, id: \.self) { i in
                    let y = h * CGFloat(i) / 4
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(WhoopIOSDesign.gridLine, lineWidth: 1)
                }

                if let band, points.count >= 2 {
                    let yHigh = h * (1 - CGFloat((band.high - lo) / span))
                    let yLow = h * (1 - CGFloat((band.low - lo) / span))
                    Rectangle()
                        .fill(WhoopIOSDesign.rangeBand)
                        .frame(width: w, height: max(yLow - yHigh, 2))
                        .offset(y: yHigh)
                }

                if points.count >= 2 {
                    Path { path in
                        for (i, pt) in points.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let y = h * (1 - CGFloat((pt.value - lo) / span))
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    if let last = points.last {
                        let x = w
                        let y = h * (1 - CGFloat((last.value - lo) / span))
                        Circle()
                            .fill(lineColor)
                            .frame(width: 10, height: 10)
                            .position(x: x, y: y)
                        Text(valueFormat(last.value))
                            .font(WhoopType.caption(11))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(WhoopIOSDesign.cardRaised))
                            .position(x: max(28, x - 24), y: max(14, y - 16))
                    }
                } else {
                    Text("Not enough data")
                        .font(WhoopType.body(14))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

#endif
