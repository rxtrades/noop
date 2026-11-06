#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// Whoople Devices hub — Device Settings cards + pairing entry (Phase 5).
struct WhoopDevicesView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @Environment(\.dismiss) private var dismiss

    @State private var showPairing = false
    @State private var showClassicWizard = false
    @State private var settingsDevice: PairedDevice?

    private var devices: [PairedDevice] {
        model.deviceRegistry?.devices.filter { $0.status != .archived } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Devices")
                        .font(WhoopType.title(28))
                        .foregroundStyle(.white)

                    Text("Pair a strap, check battery, and broadcast heart rate.")
                        .font(WhoopType.body(15))
                        .foregroundStyle(WhoopIOSDesign.textBody)

                    if devices.isEmpty {
                        emptyCard
                    } else {
                        ForEach(devices) { device in
                            Button { settingsDevice = device } label: {
                                deviceCard(device)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button { showPairing = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("ADD A DEVICE")
                                .font(WhoopType.labelCaps(13))
                                .tracking(1)
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Button { showClassicWizard = true } label: {
                        Text("Browse all device types")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.strainBlue)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .whoopPageBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(WhoopIOSDesign.strainBlue)
                }
            }
            .toolbarBackground(WhoopIOSDesign.bgBase.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $settingsDevice) { device in
                NavigationStack {
                    WhoopDeviceSettingsView(device: device)
                }
                .preferredColorScheme(.dark)
            }
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
        }
    }

    private var emptyCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("No strap paired")
                    .font(WhoopType.cardTitle())
                    .foregroundStyle(.white)
                Text("Add \(WhoopleBranding.displayName) or another band to unlock recovery, strain, and sleep.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
            }
        }
    }

    private func deviceCard(_ device: PairedDevice) -> some View {
        let isActive = device.status == .active
        let showLive = isActive && live.connected
        return WhoopCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(WhoopIOSDesign.cardRaised)
                        .frame(width: 44, height: 44)
                    Capsule()
                        .stroke(WhoopIOSDesign.textSecondary, lineWidth: 1.5)
                        .frame(width: 10, height: 18)
                    Circle()
                        .fill(showLive ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textTertiary)
                        .frame(width: 6, height: 6)
                        .offset(x: 8, y: 8)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.displayName)
                        .font(WhoopType.cardTitle(16))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(showLive ? "Connected · Live" : (isActive ? "Active" : "Paired"))
                        .font(WhoopType.caption())
                        .foregroundStyle(showLive ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.textSecondary)
                }
                Spacer()
                if showLive, let pct = live.batteryPct.map({ Int($0.rounded()) }) {
                    Text("\(pct)%")
                        .font(WhoopType.metric(17))
                        .foregroundStyle(pct <= 15 ? WhoopIOSDesign.recoveryRed : .white)
                        .monospacedDigit()
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
        }
    }
}

#endif
