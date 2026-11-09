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
                    Text("DEVICES")
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.4)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)

                    Text("Manage paired straps and open Device Settings.")
                        .font(WhoopType.body(14))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

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
                            Text("PAIR YOUR WHOOPLE")
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

                    // Restored from classic NOOP: the multi-device manager (Oura ring, other HR straps)
                    // that the Whoople Devices hub had reduced to a small "Browse all device types" link.
                    otherDevicesSection
                        .padding(.top, 12)
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .whoopPageBackground()
            .toolbar {
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

    /// "Other devices" — pair and sync an Oura ring or another band via the classic NOOP flows.
    private var otherDevicesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OTHER DEVICES")
                .font(WhoopType.rowCaps(12))
                .tracking(1)
                .foregroundStyle(WhoopIOSDesign.textSecondary)
            VStack(spacing: 8) {
                NavigationLink {
                    WhoopOtherDevicesDestination()
                } label: {
                    otherDeviceRow(icon: "arrow.triangle.2.circlepath",
                                   title: "SYNC OTHER DEVICES",
                                   subtitle: "Oura ring, heart-rate straps & more")
                }
                .buttonStyle(.plain)

                Button { showClassicWizard = true } label: {
                    otherDeviceRow(icon: "plus.circle",
                                   title: "ADD ANOTHER DEVICE",
                                   subtitle: "Pair an Oura ring or another band")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func otherDeviceRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(WhoopType.rowCaps(14))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(WhoopType.caption(12))
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: WhoopIOSDesign.cardRadius, style: .continuous)
                .fill(WhoopIOSDesign.surfaceList)
        )
        .contentShape(Rectangle())
    }

    private var emptyCard: some View {
        WhoopCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("No device paired")
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
                    Text(WhoopleBranding.sanitizeDisplayName(device.displayName))
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

/// The classic NOOP Devices manager (every paired band incl. Oura ring: pair, sync, make active),
/// pushed under Whoople chrome with the same wrapper the pre-Whoople Devices sheet used.
struct WhoopOtherDevicesDestination: View {
    var body: some View {
        DevicesView()
            .background(StrandPalette.surfaceBase.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .preferredColorScheme(.dark)
    }
}

#endif
