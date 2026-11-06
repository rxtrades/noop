#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// WHOOP-style Device Settings (Mobbin 119/120): Status / Advanced, battery, Broadcast HR, Pair/Unpair.
struct WhoopDeviceSettingsView: View {
    var device: PairedDevice?

    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @Environment(\.dismiss) private var dismiss

    @AppStorage(HrBroadcaster.defaultsKey) private var phoneBroadcastHr = false
    @AppStorage(PuffinExperiment.broadcastHrKey) private var strapBroadcastHr = false
    @State private var tab: Tab = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("devicesettingsadvanced") || (args.contains("--whoople-device-tab") && args.contains("advanced")) {
            return .advanced
        }
        return .status
    }()
    @StateObject private var hrBroadcaster = HrBroadcaster()
    @State private var showPairing = false
    @State private var showClassicWizard = false
    @State private var showUnpairConfirm = false

    enum Tab: String, CaseIterable, Identifiable {
        case status = "STATUS"
        case advanced = "ADVANCED"
        var id: String { rawValue }
    }

    private var batteryPct: Int? {
        live.batteryPct.map { Int($0.rounded()) }
    }

    private var deviceTitle: String {
        let raw: String = {
            if let device { return device.displayName }
            if let name = model.deviceRegistry?.devices.first(where: { $0.status == .active })?.displayName {
                return name
            }
            return "\(WhoopleBranding.displayName) Strap"
        }()
        return WhoopleBranding.sanitizeDisplayName(raw).uppercased()
    }

    private var deviceIdShort: String {
        device?.id ?? model.deviceRegistry?.devices.first(where: { $0.status == .active })?.id ?? "—"
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
            .padding(.bottom, 48)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DEVICE SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.2)
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.white)
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
        .fullScreenCover(isPresented: $showPairing) {
            WhoopPairingFlowView(
                onFinished: { showPairing = false },
                onOpenClassicWizard: {
                    showPairing = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showClassicWizard = true
                    }
                }
            )
        }
        .sheet(isPresented: $showClassicWizard) {
            AddDeviceWizard(live: live, onClose: { showClassicWizard = false })
                .preferredColorScheme(.dark)
        }
        .confirmationDialog("Unpair this device?", isPresented: $showUnpairConfirm, titleVisibility: .visible) {
            Button("Unpair", role: .destructive) {
                if let id = device?.id ?? model.deviceRegistry?.devices.first(where: { $0.status == .active })?.id {
                    model.deviceRegistry?.archive(id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the Bluetooth connection for this strap.")
        }
    }

    private var headerStats: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(live.connected ? "CONNECTED TO" : "NOT CONNECTED")
                    .font(WhoopType.caption(10))
                    .tracking(1.1)
                    .foregroundStyle(live.connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.recoveryYellow)
                HStack(spacing: 6) {
                    Text(deviceTitle)
                        .font(WhoopType.cardTitle(15))
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
                    .tracking(1.1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                HStack(spacing: 4) {
                    Text(lastSyncLabel)
                        .font(WhoopType.cardTitle(15))
                        .foregroundStyle(.white)
                    Image(systemName: live.connected ? "checkmark.icloud.fill" : "icloud.slash")
                        .foregroundStyle(live.connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textTertiary)
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
        HStack(spacing: 28) {
            ForEach(Tab.allCases) { t in
                Button { tab = t } label: {
                    VStack(spacing: 8) {
                        Text(t.rawValue)
                            .font(WhoopType.labelCaps(12))
                            .tracking(1.2)
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
        }
    }

    private var strapHero: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
                .frame(width: 168, height: 168)
            VStack(spacing: 12) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2E333A"), Color(hex: "#14171B")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 108, height: 34)
                    .overlay(
                        HStack(spacing: 6) {
                            Capsule().fill(Color.white.opacity(0.12)).frame(width: 22, height: 10)
                            Text("W")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    )
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
                Text(WhoopleBranding.displayName.uppercased())
                    .font(WhoopType.caption(10))
                    .tracking(1.6)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            if let pct = batteryPct, pct <= 20 {
                Text("CHARGE YOUR STRAP")
                    .font(WhoopType.labelCaps(9))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(WhoopIOSDesign.recoveryRed))
                    .offset(x: 8, y: -6)
            }
        }
    }

    private var batteryBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(batteryPct.map { "\($0)%" } ?? "—")
                    .font(WhoopType.metric(44))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                batteryMeter
            }
            Text(deviceModelLabel.uppercased())
                .font(WhoopType.caption(11))
                .tracking(0.8)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var batteryMeter: some View {
        let pct = Double(batteryPct ?? 0) / 100
        return ZStack(alignment: .bottom) {
            Capsule().stroke(WhoopIOSDesign.ringTrack, lineWidth: 1.5)
            Capsule().fill(batteryTint)
                .frame(height: 58 * max(pct, 0.04))
        }
        .frame(width: 14, height: 58)
    }

    private var batteryTint: Color {
        guard let pct = batteryPct else { return WhoopIOSDesign.textTertiary }
        if pct <= 15 { return WhoopIOSDesign.recoveryRed }
        if pct <= 40 { return WhoopIOSDesign.recoveryYellow }
        return WhoopIOSDesign.recoveryGreen
    }

    private var deviceModelLabel: String {
        device?.displayName ?? "\(WhoopleBranding.displayName) strap"
    }

    private var broadcastCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.white).frame(width: 36, height: 36)
                Image(systemName: "heart.fill").foregroundStyle(.black)
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
                .fill(WhoopIOSDesign.surfaceList)
        )
    }

    private var advancedContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 28) {
                infoColumn(icon: "applewatch", title: "DEVICE ID", value: WhoopleBranding.sanitizeDisplayName(deviceIdShort))
                infoColumn(icon: "memorychip", title: "FIRMWARE", value: live.strapFirmware ?? "—")
            }
            .padding(.top, 4)

            actionCard(icon: "plus.circle", title: "PAIR A DEVICE",
                       caption: "Pair a strap to Whoople. This will replace any existing pairing.") {
                showPairing = true
            }
            actionCard(icon: "minus.circle", title: "UNPAIR DEVICE",
                       caption: "Unpair your strap from Whoople. This will remove the Bluetooth connection.") {
                showUnpairConfirm = true
            }
            actionCard(icon: "memorychip", title: "FIRMWARE CHECK",
                       caption: "Check and install the latest strap firmware when available.") {
                // No OTA in Whoople yet — surface status only.
            }

            Toggle(isOn: $strapBroadcastHr) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("STRAP BROADCAST HR")
                        .font(WhoopType.rowCaps(12))
                        .tracking(0.7)
                        .foregroundStyle(.white)
                    Text("Experimental direct broadcast")
                        .font(WhoopType.caption(11))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                }
            }
            .tint(WhoopIOSDesign.recoveryGreen)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                    .fill(WhoopIOSDesign.surfaceList)
            )
            .onChange(of: strapBroadcastHr) { _, on in
                model.ble.setBroadcastHr(on)
            }
        }
    }

    private func infoColumn(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.white)
            Text(title)
                .font(WhoopType.caption(10))
                .tracking(1)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            Text(value)
                .font(WhoopType.cardTitle(15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionCard(icon: String, title: String, caption: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 26)
                    Text(title)
                        .font(WhoopType.rowCaps(13))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                        .fill(WhoopIOSDesign.surfaceList)
                )
            }
            .buttonStyle(.plain)
            Text(caption)
                .font(WhoopType.caption(12))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .padding(.horizontal, 4)
        }
    }
}

#endif
