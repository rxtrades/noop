#if os(iOS)
import SwiftUI
import StrandDesign

/// Large photoreal strap hero for Device Settings (Mobbin 119 / d035bbaf).
/// Own generated product renders (knit band + sensor pod) — not WHOOP marketing assets.
/// Slow turntable crossfade; swaps to charging / PowerPack stills when those states are active.
struct WhoopStrapHero3DView: View {
    var charging: Bool
    var packAttached: Bool
    var batteryFraction: Double
    var reduceMotion: Bool = false

    /// Large hero — fills top of Device Settings like WHOOP.
    var size: CGFloat = 260

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.055, green: 0.065, blue: 0.075))

            WhoopStrapTurntable(
                charging: charging,
                packAttached: packAttached,
                reduceMotion: reduceMotion
            )
            .padding(6)

            if charging {
                // Soft green glow veil to sell charging even on still frames
                RadialGradient(
                    colors: [
                        WhoopIOSDesign.recoveryGreen.opacity(0.18),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: size * 0.55
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityLabel(charging ? "Strap charging" : (packAttached ? "Strap with PowerPack" : "Strap"))
    }
}

private struct WhoopStrapTurntable: View {
    var charging: Bool
    var packAttached: Bool
    var reduceMotion: Bool

    private let frames = ["StrapHero0", "StrapHero1", "StrapHero2", "StrapHero3"]
    @State private var index = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 3600 : 1.75, paused: reduceMotion)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate / 1.75)
            let frameName = currentFrameName(tick: tick)
            Image(frameName)
                .resizable()
                .scaledToFit()
                .transition(.opacity)
                .id(frameName)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.85), value: frameName)
        }
    }

    private func currentFrameName(tick: Int) -> String {
        if packAttached { return "StrapHeroPack" }
        if charging { return "StrapHeroCharging" }
        if reduceMotion { return frames[0] }
        return frames[abs(tick) % frames.count]
    }
}

#endif
