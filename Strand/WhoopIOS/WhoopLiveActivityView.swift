#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore
import Combine

/// WHOOP-style Live Activity (Mobbin 086/063): blue header, timer, HR circle, zones, End & Save.
struct WhoopLiveActivityView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @Environment(\.dismiss) private var dismiss

    @State private var tick = Date()
    @State private var showDetail = false
    @State private var endedRow: WorkoutRow?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var workout: AppModel.ActiveWorkout? { model.activeWorkout }
    private var hr: Int { live.heartRate ?? workout?.avgHr ?? 0 }
    private var zone: Int { hrZone(hr) }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            timerBar
            Spacer(minLength: 8)
            hrCircle
            hrSpark
            Spacer(minLength: 8)
            metricsRow
            HStack {
                pageDots
                Spacer()
                Button { showDetail = true } label: {
                    HStack(spacing: 4) {
                        Text("Activity Strain")
                            .font(WhoopType.caption(12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "#0A1A2E"), WhoopIOSDesign.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .onReceive(timer) { tick = $0 }
        .onAppear {
            if model.activeWorkout == nil {
                // Demo / open without a session — still show the live HR surface.
            }
        }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                WhoopActivityDetailView(
                    sport: workout?.sport ?? "Activity",
                    strain: workout?.liveStrain ?? endedRow?.strain,
                    avgHr: workout.map { $0.avgHr } ?? endedRow?.avgHr,
                    peakHr: workout.map { $0.peakHr } ?? endedRow?.maxHr,
                    calories: endedRow?.energyKcal.map { Int($0.rounded()) },
                    durationS: endedRow?.durationS ?? elapsedSeconds,
                    zoneMinutes: estimatedZoneMinutes
                )
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.large])
        }
        .sheet(isPresented: Binding(
            get: { endedRow != nil },
            set: { if !$0 { endedRow = nil } }
        )) {
            if let row = endedRow {
                NavigationStack {
                    WhoopActivityDetailView(
                        sport: row.sport,
                        strain: row.strain,
                        avgHr: row.avgHr,
                        peakHr: row.maxHr,
                        calories: row.energyKcal.map { Int($0.rounded()) },
                        durationS: row.durationS,
                        zoneMinutes: nil
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                endedRow = nil
                                dismiss()
                            }
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                model.discardWorkout()
                dismiss()
            } label: {
                Label("Discard", systemImage: "trash")
                    .font(WhoopType.labelCaps(12))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                if model.activeWorkout != nil {
                    model.endWorkout()
                    endedRow = model.lastWorkout
                    if endedRow == nil { dismiss() }
                } else {
                    dismiss()
                }
            } label: {
                Label("End & Save", systemImage: "square.and.arrow.down")
                    .font(WhoopType.labelCaps(12))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(WhoopIOSDesign.strainBlue.ignoresSafeArea(edges: .top))
    }

    private var timerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: workout?.isPaused == true ? "pause.fill" : "play.fill")
                .foregroundStyle(.white)
            Text(timerLabel)
                .font(WhoopType.metric(18))
                .foregroundStyle(.white)
                .monospacedDigit()
            Spacer()
            if let sport = workout?.sport {
                Text(sport.uppercased())
                    .font(WhoopType.caption(11))
                    .tracking(0.8)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
    }

    private var hrCircle: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 210, height: 210)
                .shadow(color: zoneColor.opacity(0.35), radius: 24)
            VStack(spacing: 4) {
                Text("HEART RATE")
                    .font(WhoopType.caption(11))
                    .tracking(1.2)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                Text(hr > 0 ? "\(hr)" : "—")
                    .font(WhoopType.hero(64))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(hr > 0 ? "Zone \(zone)" : "Waiting")
                    .font(WhoopType.cardTitle(16))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 12)
    }

    private var hrSpark: some View {
        WhoopSparkline(
            values: (workout?.samples.suffix(60).map { Double($0.bpm) })
                ?? (hr > 0 ? [Double(hr)] : []),
            tint: WhoopIOSDesign.strainBlue,
            fill: WhoopIOSDesign.strainBlue.opacity(0.15)
        )
        .frame(height: 72)
        .padding(.horizontal, 8)
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            metricCell(icon: "heart.fill", title: "AVG HR",
                       value: workout.map { $0.avgHr > 0 ? "\($0.avgHr)" : "—" } ?? (hr > 0 ? "\(hr)" : "—"))
            Divider().frame(height: 44).overlay(WhoopIOSDesign.cardBorder)
            metricCell(icon: "figure.strengthtraining.traditional", title: "STRAIN",
                       value: workout.map { String(format: "%.1f", $0.liveStrain) } ?? "—")
            Divider().frame(height: 44).overlay(WhoopIOSDesign.cardBorder)
            metricCell(icon: "flame.fill", title: "CALORIES",
                       value: caloriesEstimate.map { "\($0)" } ?? "—")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
    }

    private func metricCell(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Text(title)
                .font(WhoopType.caption(10))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Text(value)
                .font(WhoopType.metric(22))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.white).frame(width: 6, height: 6)
            Circle().fill(WhoopIOSDesign.textTertiary).frame(width: 6, height: 6)
            Circle().fill(WhoopIOSDesign.textTertiary).frame(width: 6, height: 6)
        }
    }

    private var timerLabel: String {
        let s = Int(elapsedSeconds)
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    private var elapsedSeconds: Double {
        _ = tick
        guard let w = workout else { return 0 }
        let paused = w.pausedDuration + (w.pausedAt.map { Date().timeIntervalSince($0) } ?? 0)
        return max(0, Date().timeIntervalSince(w.start) - paused)
    }

    private var caloriesEstimate: Int? {
        guard let w = workout, w.avgHr > 0 else { return nil }
        // Rough MET-less estimate from elapsed minutes * avg HR factor.
        let mins = elapsedSeconds / 60
        return max(1, Int(mins * Double(w.avgHr) * 0.063))
    }

    private var estimatedZoneMinutes: [Int]? {
        guard let samples = workout?.samples, !samples.isEmpty else { return nil }
        var buckets = Array(repeating: 0, count: 5)
        for s in samples {
            let z = max(1, min(5, hrZone(s.bpm))) - 1
            buckets[z] += 1
        }
        // samples ~1Hz → minutes
        return buckets.map { max(0, $0 / 60) }
    }

    private func hrZone(_ bpm: Int) -> Int {
        // Simple fixed bands without profile max-HR.
        switch bpm {
        case ..<0: return 1
        case ..<120: return 1
        case ..<140: return 2
        case ..<160: return 3
        case ..<175: return 4
        default: return 5
        }
    }

    private var zoneColor: Color {
        WhoopActivityDetailView.zoneColor(zone)
    }
}

#endif
