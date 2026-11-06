#if os(iOS)
import SwiftUI
import StrandDesign

/// Journal setup / customize: show or hide questions, add a custom bool prompt.
struct WhoopJournalCustomizeView: View {
    @ObservedObject var catalog: JournalCatalogStore
    var importedQuestions: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    private var visible: [JournalCatalogItem] {
        catalog.resolvedItems(imported: importedQuestions, includeHidden: false)
            .sorted { ($0.sortIndex, $0.display) < ($1.sortIndex, $1.display) }
    }

    private var hidden: [JournalCatalogItem] {
        catalog.resolvedItems(imported: importedQuestions, includeHidden: true)
            .filter(\.hidden)
            .sorted { ($0.sortIndex, $0.display) < ($1.sortIndex, $1.display) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose which behaviours show in your daily journal. Hidden items stay in history.")
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.textBody)

                section("ACTIVE") {
                    ForEach(visible) { item in
                        row(item, active: true)
                    }
                }

                if !hidden.isEmpty {
                    section("HIDDEN") {
                        ForEach(hidden) { item in
                            row(item, active: false)
                        }
                    }
                }

                section("ADD QUESTION") {
                    HStack(spacing: 10) {
                        TextField("e.g. Meditated?", text: $draft)
                            .foregroundStyle(.white)
                            .textInputAutocapitalization(.sentences)
                        Button {
                            let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            catalog.addCustom(t)
                            draft = ""
                        } label: {
                            Text("ADD")
                                .font(WhoopType.labelCaps(12))
                                .tracking(0.8)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                            .fill(WhoopIOSDesign.card)
                    )
                }
            }
            .padding(.horizontal, WhoopIOSDesign.pageMargin)
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationTitle("Customize Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(WhoopType.rowCaps(12))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            content()
        }
    }

    private func row(_ item: JournalCatalogItem, active: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.display)
                    .font(WhoopType.body(15))
                    .foregroundStyle(.white)
                Text(item.group.title)
                    .font(WhoopType.caption(11))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer()
            if active {
                Button {
                    catalog.remove(item.canonical)
                } label: {
                    Text(item.custom ? "Remove" : "Hide")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.stressHigh)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    catalog.restore(item.canonical)
                } label: {
                    Text("Restore")
                        .font(WhoopType.caption(12))
                        .foregroundStyle(WhoopIOSDesign.strainBlue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

#endif
