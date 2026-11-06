#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-style Journal entry (Mobbin 179): warm gradient header, week strip, X/✓ cards, NOTES, SAVE.
struct WhoopJournalView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss

    @StateObject private var catalog = JournalCatalogStore()

    /// 0 = today, positive = days ago, negative = tomorrow (matches JournalLogCard).
    @State private var dayOffset = 0
    @State private var answers: [String: Bool] = [:]
    @State private var notes = ""
    @State private var importedQuestions: [String] = []
    @State private var showSaved = false
    @State private var showCustomize = false
    @State private var saving = false

    private var dayKey: String {
        Repository.localDayKey(
            Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date())
    }

    private var dayDate: Date {
        Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
    }

    private var items: [JournalCatalogItem] {
        catalog.resolvedItems(imported: importedQuestions, includeHidden: false)
            .filter { !$0.kind.isNumeric } // Phase 7: bool cards; numeric stays on classic Insights
            .sorted { ($0.group.rawValue, $0.sortIndex, $0.display) < ($1.group.rawValue, $1.sortIndex, $1.display) }
    }

    var body: some View {
        ZStack {
            journalChrome
            if showSaved {
                WhoopJournalSavedView {
                    showSaved = false
                    dismiss()
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .task(id: dayOffset) { await reload() }
        .sheet(isPresented: $showCustomize) {
            NavigationStack {
                WhoopJournalCustomizeView(catalog: catalog, importedQuestions: importedQuestions)
            }
            .preferredColorScheme(.dark)
        }
        .animation(.easeOut(duration: 0.25), value: showSaved)
    }

    private var journalChrome: some View {
        VStack(spacing: 0) {
            header
            weekStrip
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(headline)
                        .font(WhoopType.title(26))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    sectionLabel("DAYTIME")

                    ForEach(items) { item in
                        questionCard(item)
                    }

                    notesCard

                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
            }

            saveBar
        }
        .background(journalBackground.ignoresSafeArea())
    }

    private var journalBackground: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#6B5344"), location: 0),
                .init(color: Color(hex: "#3A322E"), location: 0.22),
                .init(color: WhoopIOSDesign.bgMid, location: 0.45),
                .init(color: WhoopIOSDesign.bgBase, location: 0.75),
                .init(color: WhoopIOSDesign.bgBottom, location: 1)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("JOURNAL")
                .font(WhoopType.labelCaps(13))
                .tracking(1.2)
                .foregroundStyle(.white)
            Spacer()
            Button { showCustomize = true } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var weekStrip: some View {
        VStack(spacing: 10) {
            HStack {
                Button { dayOffset += 1 } label: {
                    Image(systemName: "chevron.left").foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(dayOffsetLabel.uppercased())
                    .font(WhoopType.labelCaps(13))
                    .tracking(1)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    if dayOffset > -1 { dayOffset -= 1 }
                } label: {
                    Image(systemName: "chevron.right").foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .opacity(dayOffset > -1 ? 1 : 0.35)
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(weekOffsets, id: \.self) { off in
                            dayPill(off).id(off)
                        }
                    }
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
                }
                .onAppear { proxy.scrollTo(dayOffset, anchor: .center) }
                .onChange(of: dayOffset) { _, v in
                    withAnimation { proxy.scrollTo(v, anchor: .center) }
                }
            }
        }
        .padding(.bottom, 6)
    }

    private var weekOffsets: [Int] {
        // Yesterday-6 … tomorrow → chronological left→right as negative-of-offset? 
        // dayOffset: 0 today, 1 yesterday → show [6,5,4,3,2,1,0,-1]
        Array(((-1)...6).reversed())
    }

    private func dayPill(_ off: Int) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: -off, to: Date()) ?? Date()
        let selected = off == dayOffset
        let df = DateFormatter()
        df.locale = .current
        return Button { dayOffset = off } label: {
            VStack(spacing: 6) {
                Text(weekdayShort(date))
                    .font(WhoopType.caption(10))
                    .foregroundStyle(selected ? .white : WhoopIOSDesign.textSecondary)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(WhoopType.cardTitle(16))
                    .foregroundStyle(.white)
                Circle()
                    .fill(selected ? Color.white : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 48, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Color.white.opacity(0.9) : Color.clear, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(selected ? 0.12 : 0.04))
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func questionCard(_ item: JournalCatalogItem) -> some View {
        let ans = answers[item.canonical]
        return HStack(spacing: 12) {
            Text(shortQuestion(item.display))
                .font(WhoopType.body(15))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            squareToggle(system: "xmark", selected: ans == false) {
                answers[item.canonical] = false
            }
            squareToggle(system: "checkmark", selected: ans == true, tint: WhoopIOSDesign.strainBlue) {
                answers[item.canonical] = true
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card.opacity(0.92))
        )
    }

    private func squareToggle(system: String, selected: Bool, tint: Color = WhoopIOSDesign.textSecondary,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selected ? .white : WhoopIOSDesign.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? tint : WhoopIOSDesign.cardRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(selected ? tint : WhoopIOSDesign.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(WhoopType.rowCaps(12))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            TextField("Add a note", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .foregroundStyle(.white)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                        .fill(WhoopIOSDesign.card.opacity(0.92))
                )
        }
        .padding(.top, 6)
    }

    private var saveBar: some View {
        Button {
            Task { await save() }
        } label: {
            Text(saving ? "SAVING…" : "SAVE JOURNAL")
                .font(WhoopType.labelCaps(14))
                .tracking(1.2)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Capsule().fill(Color.white))
        }
        .buttonStyle(.plain)
        .disabled(saving)
        .padding(.horizontal, WhoopIOSDesign.pageMargin)
        .padding(.vertical, 12)
        .background(
            WhoopIOSDesign.bgBottom.opacity(0.92)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(WhoopType.rowCaps(12))
                .tracking(1)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Rectangle().fill(WhoopIOSDesign.cardBorder).frame(height: 1)
        }
    }

    private var headline: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM d"
        let when = dayOffset == 0 ? "today" : (dayOffset == 1 ? "yesterday" : (dayOffset == -1 ? "tomorrow" : df.string(from: dayDate)))
        if dayOffset == 0 || dayOffset == 1 || dayOffset == -1 {
            return "What's happening \(when), \(df.string(from: dayDate))?"
        }
        return "What's happening on \(df.string(from: dayDate))?"
    }

    private var dayOffsetLabel: String {
        switch dayOffset {
        case 0: return "Today"
        case 1: return "Yesterday"
        case -1: return "Tomorrow"
        default:
            let df = DateFormatter()
            df.dateFormat = "EEE d"
            return df.string(from: dayDate)
        }
    }

    private func weekdayShort(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df.string(from: date)
    }

    /// Soften starter phrasing for card density (keep canonical for DB).
    private func shortQuestion(_ display: String) -> String {
        var s = display
        if s.hasPrefix("Did you ") { s = String(s.dropFirst("Did you ".count)) }
        if s.hasSuffix("?") { s = String(s.dropLast()) }
        if !s.isEmpty { s = s.prefix(1).uppercased() + s.dropFirst() }
        return s.isEmpty ? display : s + "?"
    }

    private func reload() async {
        let imported = await repo.importedJournalEntries(days: 120)
        importedQuestions = Array(Set(imported.map(\.question))).sorted()
        let native = await repo.nativeJournalAnswers(day: dayKey)
        answers = native
        // Prefer notes from any native row for this day.
        let entries = await repo.journalEntries(days: 14)
        notes = entries.first(where: { $0.day == dayKey && ($0.notes?.isEmpty == false) })?.notes ?? ""
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let note = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var first = true
        for (q, yes) in answers {
            let n: String? = (first && !note.isEmpty) ? note : nil
            await repo.saveJournalAnswer(day: dayKey, question: q, answeredYes: yes, notes: n)
            first = false
        }
        // If only notes were typed with no answers, still persist a lightweight marker on a notes question.
        if answers.isEmpty, !note.isEmpty {
            await repo.saveJournalAnswer(day: dayKey, question: "Notes", answeredYes: true, notes: note)
        }
        showSaved = true
    }
}

#endif
