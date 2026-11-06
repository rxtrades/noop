#if os(iOS)
import SwiftUI
import StrandDesign

/// Full-screen Whoople pairing step flow (Mobbin 150–153), then hands off to AddDeviceWizard.
struct WhoopPairingFlowView: View {
    var onFinished: () -> Void
    var onOpenClassicWizard: () -> Void

    @State private var step: Step = .intro
    @State private var pulse = false

    enum Step: Int, CaseIterable {
        case intro, modeHelp, scanning, success
    }

    var body: some View {
        ZStack {
            WhoopIOSDesign.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { onFinished() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("PAIR DEVICE")
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 12)
                stepContent
                Spacer(minLength: 12)
                bottomCTA
                    .padding(.horizontal, WhoopIOSDesign.pageMargin)
                    .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case .intro:
            VStack(spacing: 22) {
                pairingIllustration(connected: false, scanning: false)
                Text("UNBOX YOUR STRAP")
                    .font(WhoopType.title(26))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Put \(WhoopleBranding.displayName) on, then put the strap into pairing mode.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        case .modeHelp:
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(WhoopIOSDesign.card)
                        .frame(width: 160, height: 160)
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(WhoopIOSDesign.strainBlue)
                }
                Text("CHECK FOR PAIRING MODE")
                    .font(WhoopType.title(24))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Press and hold the button on your strap until the LED pulses. Keep it near your phone.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        case .scanning:
            VStack(spacing: 22) {
                pairingIllustration(connected: false, scanning: true)
                Text("SEARCHING…")
                    .font(WhoopType.title(26))
                    .foregroundStyle(.white)
                Text("Looking for a strap in pairing mode nearby.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
            }
            .task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                withAnimation(.easeOut(duration: 0.35)) { step = .success }
            }
        case .success:
            VStack(spacing: 22) {
                pairingIllustration(connected: true, scanning: false)
                Text("\(WhoopleBranding.displayName.uppercased()) CONNECTED")
                    .font(WhoopType.title(24))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Your strap is ready to go. Finish setup to sync recovery, strain, and sleep.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func pairingIllustration(connected: Bool, scanning: Bool) -> some View {
        HStack(spacing: 18) {
            phoneGlyph
            ZStack {
                if scanning {
                    Circle()
                        .stroke(WhoopIOSDesign.strainBlue.opacity(pulse ? 0.55 : 0.15), lineWidth: 3)
                        .frame(width: pulse ? 64 : 44, height: pulse ? 64 : 44)
                }
                Circle()
                    .fill(connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.strainBlue)
                    .frame(width: 44, height: 44)
                    .shadow(color: (connected ? WhoopIOSDesign.recoveryGreen : WhoopIOSDesign.strainBlue).opacity(0.55),
                            radius: connected ? 16 : 10)
                Image(systemName: connected ? "checkmark" : (scanning ? "dot.radiowaves.left.and.right" : "link"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            strapGlyph
        }
        .padding(.vertical, 12)
    }

    private var phoneGlyph: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(WhoopIOSDesign.cardRaised)
            .frame(width: 56, height: 96)
            .overlay(
                Text("W")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(WhoopIOSDesign.cardBorder, lineWidth: 1)
            )
    }

    private var strapGlyph: some View {
        Capsule(style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#2A2F36"), Color(hex: "#12151A")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(width: 110, height: 34)
            .overlay(
                Text("W")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            )
    }

    @ViewBuilder private var bottomCTA: some View {
        switch step {
        case .intro:
            primaryButton("CONTINUE") { step = .modeHelp }
        case .modeHelp:
            VStack(spacing: 12) {
                primaryButton("START SCANNING") { step = .scanning }
                Button("More device types") { onOpenClassicWizard() }
                    .font(WhoopType.body(14))
                    .foregroundStyle(WhoopIOSDesign.strainBlue)
            }
        case .scanning:
            Text("Keep your strap close…")
                .font(WhoopType.body(14))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(maxWidth: .infinity)
        case .success:
            VStack(spacing: 12) {
                primaryButton("CONTINUE") {
                    onOpenClassicWizard()
                }
                outlinedButton("DONE") { onFinished() }
            }
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(WhoopType.labelCaps(14))
                .tracking(1.2)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white))
        }
        .buttonStyle(.plain)
    }

    private func outlinedButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(WhoopType.labelCaps(14))
                .tracking(1.2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().stroke(Color.white, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

#endif
