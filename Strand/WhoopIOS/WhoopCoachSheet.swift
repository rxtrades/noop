#if os(iOS)
import SwiftUI
import StrandDesign

/// WHOOP-style Coach chat sheet from the glowing W (Mobbin 024 / 064).
/// Reuses AICoachEngine; API-key setup lives under Settings › Coach when Whoople chrome is on.
struct WhoopCoachSheet: View {
    @EnvironmentObject private var coach: AICoachEngine
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ""
    @FocusState private var focused: Bool

    private var suggestions: [String] { coach.suggestions }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider().overlay(WhoopIOSDesign.cardBorder)
                chatBody
                inputBar
            }
            .whoopPageBackground()
            .preferredColorScheme(.dark)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                WhoopleMark(size: 28)
                Text("Coach")
                    .font(WhoopType.cardTitle(16))
                    .foregroundStyle(.white)
                Text("v6")
                    .font(WhoopType.caption(10))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(WhoopIOSDesign.cardRaised))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var chatBody: some View {
        if !coach.hasKey {
            VStack(spacing: 16) {
                Spacer()
                Text("Connect a provider in Settings to chat with Coach.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Text("Settings › App Settings › AI Settings holds your API key. The W button opens this chat sheet.")
                    .font(WhoopType.caption(12))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if coach.messages.isEmpty {
                            Text("Ask about recovery, sleep, or today’s strain. Suggestions below use your recent summary.")
                                .font(WhoopType.body(14))
                                .foregroundStyle(WhoopIOSDesign.textBody)
                                .padding(.bottom, 8)
                            FlowChips(items: suggestions) { send($0) }
                        }
                        ForEach(coach.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: coach.messages.count) { _, _ in
                    if let last = coach.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(WhoopType.body(15))
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isUser ? WhoopIOSDesign.strainBlue.opacity(0.35) : WhoopIOSDesign.card)
                )
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Whoople anything", text: $draft)
                .focused($focused)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Capsule().fill(WhoopIOSDesign.cardRaised))
                .onSubmit { send(draft) }
                .disabled(!coach.hasKey || coach.sending)
            Button {
                send(draft)
            } label: {
                Image(systemName: coach.sending ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(coach.hasKey ? WhoopIOSDesign.strainBlue : WhoopIOSDesign.textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!coach.hasKey || coach.sending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(WhoopIOSDesign.bgBase.opacity(0.95))
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft = ""
        Task { await coach.send(trimmed) }
    }
}

/// Simple wrapping chip row for coach suggestions.
private struct FlowChips: View {
    var items: [String]
    var onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    Text(item)
                        .font(WhoopType.caption(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(WhoopIOSDesign.cardRaised))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#endif
