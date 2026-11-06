#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-style floating pill: Title Case 10pt, selected rounded-rect pill, glowing W coach button.
struct WhoopFloatingTabBar: View {
    @Binding var selectedTab: Int
    var coachEnabled: Bool
    var onReselect: (Int) -> Void
    var onFAB: () -> Void

    private struct Item: Identifiable {
        let id: Int
        let tag: Int
        let title: String
        let icon: String
    }

    private var items: [Item] {
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
            HStack(spacing: 2) {
                ForEach(items) { item in
                    tabButton(item)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(Capsule(style: .continuous).fill(WhoopIOSDesign.tabBarFill.opacity(0.92)))
                    .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
            }
            fabButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .regular))
                    .symbolVariant(selected ? .fill : .none)
                Text(item.title)
                    .font(WhoopType.tab())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Color.white : WhoopIOSDesign.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                }
            }
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
                            startRadius: 6,
                            endRadius: fabPulse ? 34 : 26
                        )
                    )
                    .frame(width: 56, height: 56)
                    .opacity(fabPulse ? 1 : 0.7)
                Circle()
                    .fill(WhoopIOSDesign.cardRaised)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                WhoopleMark(size: 48)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Coach")
    }
}

#endif
