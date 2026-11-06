#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - + menu (Mobbin My Day)

struct WhoopPlusMenuSheet: View {
    var onStartActivity: () -> Void
    var onAddActivity: () -> Void
    var onJournal: () -> Void
    var onLive: () -> Void
    var onBreathwork: () -> Void

    @State private var menuAppear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(WhoopIOSDesign.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 18)

            VStack(spacing: 10) {
                menuRow("Start Activity", icon: "play.fill", tint: WhoopIOSDesign.strainBlue, index: 0, action: onStartActivity)
                menuRow("Add Activity", icon: "plus", tint: WhoopIOSDesign.mint, index: 1, action: onAddActivity)
                menuRow("Journal", icon: "square.and.pencil", tint: WhoopIOSDesign.fabGlowPurple, index: 2, action: onJournal)
                menuRow("Breathwork", icon: "wind", tint: WhoopIOSDesign.sleepBlue, index: 3, action: onBreathwork)
                menuRow("Live", icon: "waveform.path.ecg", tint: WhoopIOSDesign.recoveryGreen, index: 4, action: onLive)
            }
            .padding(.horizontal, 16)
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            WhoopIOSDesign.cardRaised.opacity(0.97)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .onAppear {
            if reduceMotion {
                menuAppear = true
            } else {
                withAnimation(WhoopIOSDesign.cardAppear) { menuAppear = true }
            }
        }
    }

    private func menuRow(_ title: String, icon: String, tint: Color, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.92)).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(WhoopType.cardTitle(17))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(menuAppear ? 1 : 0)
        .offset(y: menuAppear ? 0 : 12)
        .animation(WhoopIOSDesign.cardAppear.delay(Double(index) * 0.05), value: menuAppear)
    }
}

// MARK: - Activity picker

enum WhoopActivityBucket: String, CaseIterable, Identifiable {
    case all = "ALL", strain = "STRAIN", recovery = "RECOVERY", sleep = "SLEEP"
    var id: String { rawValue }

    func includes(_ sport: WorkoutCatalog.Sport) -> Bool {
        let n = sport.name.lowercased()
        switch self {
        case .all: return true
        case .strain:
            return !recoveryNames.contains(where: { n.contains($0) }) && !sleepNames.contains(where: { n.contains($0) })
        case .recovery:
            return recoveryNames.contains(where: { n.contains($0) })
        case .sleep:
            return sleepNames.contains(where: { n.contains($0) })
        }
    }

    private var recoveryNames: [String] { ["yoga", "pilates", "stretch", "meditation", "breath", "mobility", "foam"] }
    private var sleepNames: [String] { ["sleep", "nap"] }
}

struct WhoopActivityPickerView: View {
    var title: String = "Start Activity"
    var onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var bucket: WhoopActivityBucket = .all

    private var filtered: [WorkoutCatalog.Sport] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return WorkoutCatalog.all.filter { sport in
            guard bucket.includes(sport) else { return false }
            if q.isEmpty { return true }
            return sport.name.lowercased().contains(q)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                    TextField("Search", text: $query)
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Capsule().fill(WhoopIOSDesign.card))
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 8)

                // Tabs
                HStack(spacing: 18) {
                    ForEach(WhoopActivityBucket.allCases) { b in
                        Button { bucket = b } label: {
                            VStack(spacing: 8) {
                                Text(b.rawValue)
                                    .font(WhoopType.labelCaps(12))
                                    .tracking(0.8)
                                    .foregroundStyle(bucket == b ? .white : WhoopIOSDesign.textSecondary)
                                Rectangle()
                                    .fill(bucket == b ? Color.white : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 14)

                Text(bucket == .all ? "ALL A–Z" : bucket.rawValue)
                    .font(WhoopType.caption(11))
                    .tracking(1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { sport in
                            Button {
                                onPick(sport.name)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: sportSymbol(sport.name))
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 28)
                                    Text(sport.name.uppercased())
                                        .font(WhoopType.rowCaps(14))
                                        .tracking(0.6)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .scrollContentBackground(.hidden)
            .background(WhoopIOSDesign.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title.uppercased())
                        .font(WhoopType.labelCaps(13))
                        .tracking(1)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .background(WhoopIOSDesign.pageBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// MARK: - Start sheet

struct WhoopStartActivitySheet: View {
    var sport: String
    var onStart: (Bool) -> Void // strainTargetEnabled
    var onChangeSport: () -> Void

    @State private var strainTarget = true

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(WhoopIOSDesign.textTertiary).frame(width: 36, height: 4).padding(.top, 10)

            Button(action: onChangeSport) {
                HStack {
                    Image(systemName: sportSymbol(sport))
                        .foregroundStyle(.white)
                    Text(sport.uppercased())
                        .font(WhoopType.rowCaps(15))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WhoopIOSDesign.card))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            Toggle(isOn: $strainTarget) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strain Target")
                        .font(WhoopType.cardTitle(16))
                        .foregroundStyle(.white)
                    Text("Guide today’s effort toward an optimal strain range")
                        .font(WhoopType.caption())
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            .tint(WhoopIOSDesign.strainBlue)
            .padding(.horizontal, 20)

            Spacer()

            Button { onStart(strainTarget) } label: {
                Text("START ACTIVITY")
                    .font(WhoopType.labelCaps(14))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(WhoopIOSDesign.strainBlue))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WhoopIOSDesign.bgBase.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#endif
