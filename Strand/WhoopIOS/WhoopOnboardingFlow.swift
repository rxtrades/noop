#if os(iOS)
import SwiftUI
import StrandDesign

/// Whoople first-run host (Mobbin 155 → pairing 158/152/153/150).
/// Replaces the classic OnboardingWizard when Whoople chrome is on.
struct WhoopOnboardingFlow: View {
    var onFinished: () -> Void

    @State private var stage: Stage = .welcome
    @State private var showClassicPairing = false

    enum Stage {
        case welcome
        case pairing
    }

    var body: some View {
        ZStack {
            switch stage {
            case .welcome:
                WhoopWelcomeSplashView(
                    onHaveDevice: {
                        withAnimation(WhoopIOSDesign.sheetSpring) { stage = .pairing }
                    },
                    onNoDevice: {
                        // Land on Home; Devices FAB / Settings can pair later.
                        onFinished()
                    }
                )
                .transition(.opacity)
            case .pairing:
                WhoopPairingFlowView(
                    onFinished: { onFinished() },
                    onOpenClassicWizard: {
                        showClassicPairing = true
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity))
            }
        }
        .animation(WhoopIOSDesign.sheetSpring, value: stage == .pairing)
        .sheet(isPresented: $showClassicPairing) {
            // Classic multi-vendor wizard still available; finishing marks onboarded.
            AddDeviceWizardHost { showClassicPairing = false; onFinished() }
                .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
    }
}

/// Lightweight host so AddDeviceWizard can be presented without LiveState construction from DemoScreens.
private struct AddDeviceWizardHost: View {
    var onClose: () -> Void
    @EnvironmentObject private var live: LiveState
    var body: some View {
        AddDeviceWizard(live: live, onClose: onClose)
    }
}

/// Welcome splash (Mobbin 155): lifestyle gradient + Whoople wordmark + white / outline CTAs.
struct WhoopWelcomeSplashView: View {
    var onHaveDevice: () -> Void
    var onNoDevice: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#3A2E28"), location: 0),
                    .init(color: Color(hex: "#1A1412"), location: 0.42),
                    .init(color: Color(hex: "#0A0C0E"), location: 0.72),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Abstract lifestyle hero (no WHOOP product photography).
            VStack {
                ZStack {
                    Ellipse()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 280, height: 180)
                        .blur(radius: 2)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#2A2F36"), Color(hex: "#12151A")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 160, height: 44)
                        .overlay(
                            Text("W")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
                        .scaleEffect(appear ? 1 : 0.92)
                        .opacity(appear ? 1 : 0)
                }
                .padding(.top, 120)
                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                WhoopleWordmark(size: 28)
                    .padding(.bottom, 36)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)

                Button(action: onHaveDevice) {
                    Text("I HAVE A \(WhoopleBranding.displayName.uppercased()) DEVICE")
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.0)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 16)

                Button(action: onNoDevice) {
                    Text("I DO NOT HAVE A \(WhoopleBranding.displayName.uppercased()) DEVICE")
                        .font(WhoopType.labelCaps(12))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                Text("A \(WhoopleBranding.displayName.uppercased()) DEVICE IS REQUIRED")
                    .font(WhoopType.caption(11))
                    .tracking(0.8)
                    .foregroundStyle(WhoopIOSDesign.textTertiary)
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                    .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(WhoopIOSDesign.cardAppear) { appear = true }
        }
    }
}

#endif
