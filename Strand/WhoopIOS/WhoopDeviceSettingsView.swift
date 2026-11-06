#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP-style Device Settings (Mobbin 119/120): Status / Advanced, battery, Broadcast HR.
struct WhoopDeviceSettingsView: View {
    var device: PairedDevice?

    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @Environment(\.dismiss) private var dismiss

    @AppStorage(HrBroadcaster.defaultsKey) private var phoneBroadcastHr = false
    @AppStorage(PuffinExperiment.broadcastHrKey) private var strapBroadcastHr = false
    @State private var tab: Tab = .status
    @StateObject private var hrBroadcaster = HrBroadcaster()

    enum Tab: String, CaseIterable, Identifiable {
        case status = "STATUS"
        case advanced = "ADVANCED"
        var id: String { rawValue }
    }

    private var batteryPct: Int? {
        guard live.connected else { return live.batteryPct.map { Int($0.rounded()) } }
        return live.batteryPct.map { Int($0.rounded()) }
    }

    private var deviceTitle: String {
        if let device {
            return device.displayName
        }
        return "\(WhoopleBranding.displayName) Strap"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerStats
                tabPicker
                if tab == .status {
                    statusContent
                } else {
                    advancedContent
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
                Text("DEVICE SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.0)
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            hrBroadcaster.bind(to: live)
            if phoneBroadcastHr { hrBroadcaster.start() }
        }
        .onDisappear { hrBroadcaster.stop() }
    }

    private var headerStats: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(live.connected ? "CONNECTED TO" : "NOT CONNECTED")
                    .font(WhoopType.caption(10))
                    .tracking(1)
                    .foregroundStyle(live.connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.recoveryYellow)
                HStack(spacing: 6) {
                    Text(deviceTitle)
                        .font(WhoopType.cardTitle(16))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("LAST SYNC")
                    .font(WhoopType.caption(10))
                    .tracking(1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                HStack(spacing: 4) {
                    Image(systemName: live.connected ? "checkmark.icloud.fill" : "icloud.slash")
                        .foregroundStyle(live.connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textTertiary)
                    Text(lastSyncLabel)
                        .font(WhoopType.cardTitle(15))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var lastSyncLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }

    private var tabPicker: some View {
        HStack(spacing: 24) {
            ForEach(Tab.allCases) { t in
                Button { tab = t } label: {
                    VStack(spacing: 8) {
                        Text(t.rawValue)
                            .font(WhoopType.labelCaps(12))
                            .tracking(1)
                            .foregroundStyle(tab == t ? .white : WhoopIOSDesign.textSecondary)
                        Rectangle()
                            .fill(tab == t ? Color.white : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var statusContent: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                strapHero
                batteryBlock
            }
            .padding(.vertical, 8)

            broadcastCard

            if let pct = batteryPct, pct <= 15 {
                WhoopStatusBanner(
                    icon: "battery.25",
                    tint: WhoopIOSDesign.recoveryRed,
                    title: String(localized: "Charge your strap"),
                    detail: String(localized: "\(pct)% — plug in before bed to keep overnight recovery.")
                )
            }
        }
    }

    private var strapHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WhoopIOSDesign.card)
                .frame(width: 150, height: 150)
            VStack(spacing: 10) {
                // Abstract strap glyph (no WHOOP product render)
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2A2F36"), Color(hex: "#15181C")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 88, height: 28)
                    .overlay(
                        Text("W")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    )
                Text(WhoopleBranding.displayName.uppercased())
                    .font(WhoopType.caption(10))
                    .tracking(1.5)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }

    private var batteryBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(batteryPct.map { "\($0)%" } ?? "—")
                    .font(WhoopType.metric(40))
                    .foregroundStyle(batteryTint)
                    .monospacedDigit()
                batteryMeter
            }
            Text(deviceModelLabel)
                .font(WhoopType.caption(11))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            if let pct = batteryPct, pct <= 20 {
                Text("CHARGE YOUR STRAP")
                    .font(WhoopType.labelCaps(11))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(WhoopIOSDesign.recoveryRed))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var batteryMeter: some View {
        let pct = Double(batteryPct ?? 0) / 100
        return ZStack(alignment: .bottom) {
            Capsule().stroke(WhoopIOSDesign.ringTrack, lineWidth: 1.5)
            Capsule().fill(batteryTint)
                .frame(height: 56 * max(pct, 0.04))
        }
        .frame(width: 14, height: 56)
    }

    private var batteryTint: Color {
        guard let pct = batteryPct else { return WhoopIOSDesign.textTertiary }
        if pct <= 15 { return WhoopIOSDesign.recoveryRed }
        if pct <= 40 { return WhoopIOSDesign.recoveryYellow }
        return WhoopIOSDesign.recoveryGreen
    }

    private var deviceModelLabel: String {
        device?.kindLabel ?? "\(WhoopleBranding.displayName) strap"
    }

    private var broadcastCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.white)
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.fill")
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("BROADCAST HEART RATE")
                    .font(WhoopType.rowCaps(12))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Text("TO COMPATIBLE APPS & DEVICES")
                    .font(WhoopType.caption(10))
                    .tracking(0.6)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { phoneBroadcastHr },
                set: { on in
                    phoneBroadcastHr = on
                    if on { hrBroadcaster.start() } else { hrBroadcaster.stop() }
                }
            ))
            .labelsHidden()
            .tint(WhoopIOSDesign.recoveryGreen)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }

    private var advancedContent: some View {
        VStack(spacing: 10) {
            advancedRow("Device ID", device?.id ?? "—")
            advancedRow("Firmware", live.strapFirmware ?? "—")
            advancedRow("Connection", live.connected ? "Connected" : "Disconnected")
            Toggle(isOn: $strapBroadcastHr) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strap Broadcast HR")
                        .font(WhoopType.cardTitle(15))
                        .foregroundStyle(.white)
                    Text("Experimental — WHOOP 5/MG family direct broadcast")
                        .font(WhoopType.caption())
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            .tint(WhoopIOSDesign.recoveryGreen)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.card)
            )
            .onChange(of: strapBroadcastHr) { _, on in
                model.ble.setBroadcastHr(on)
            }
        }
    }

    private func advancedRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(WhoopType.body(15))
                .foregroundStyle(WhoopIOSDesign.textBody)
            Spacer()
            Text(value)
                .font(WhoopType.cardTitle(15))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.card)
        )
    }
}

private extension PairedDevice {
    var kindLabel: String {
        // Best-effort display without WHOOP wordmark as brand — model name OK when it's hardware.
        displayName
    }
}

#endif
