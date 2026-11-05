#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-style floating pill tab bar + glowing W FAB (visual chrome over the system TabView).
struct WhoopFloatingTabBar: View {
    @Binding var selectedTab: Int
    var coachEnabled: Bool // reserved for future Coach tab visibility
    var onReselect: (Int) -> Void
    var onFAB: () -> Void

    private struct Item: Identifiable {
        let id: Int
        let tag: Int
        let title: LocalizedStringKey
        let icon: String
    }

    private var items: [Item] {
        // WHOOP four-up: Home · Health · Community · More (Coach stays under More, not in the pill).
        [
            Item(id: 0, tag: 0, title: "Home", icon: "house"),
            Item(id: 1, tag: 1, title: "Health", icon: "heart.text.square"),
            Item(id: 2, tag: 2, title: "Community", icon: "person.3"),
            Item(id: 3, tag: 4, title: "More", icon: "line.3.horizontal"),
        ]
    }

    @State private var fabPulse = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    tabButton(item)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(Capsule(style: .continuous).fill(WhoopIOSDesign.card.opacity(0.92)))
                    .overlay(Capsule(style: .continuous).stroke(WhoopIOSDesign.cardBorder, lineWidth: 0.5))
            }
            fabButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .onAppear {
            guard !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                fabPulse = true
            }
        }
    }

    private func tabButton(_ item: Item) -> some View {
        let selected = selectedTab == item.tag
        return Button {
            if selected { onReselect(item.tag) }
            else {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { selectedTab = item.tag }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .regular))
                    .symbolVariant(selected ? .fill : .none)
                    .scaleEffect(selected ? 1.06 : 1)
                Text(item.title)
                    .font(.system(size: 10, weight: selected ? .bold : .semibold))
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            .foregroundStyle(selected ? Color.white : WhoopIOSDesign.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selected)
    }

    private var fabButton: some View {
        Button(action: onFAB) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                WhoopIOSDesign.fabGlowPurple,
                                WhoopIOSDesign.fabGlowBlue,
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: fabPulse ? 34 : 26
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(fabPulse ? 0.95 : 0.65)
                Circle()
                    .fill(WhoopIOSDesign.cardElevated)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(WhoopIOSDesign.cardBorder, lineWidth: 0.5))
                WhoopleMark(size: 48)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Devices and quick actions")
    }
}

#endif
