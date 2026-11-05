#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Whoople / WHOOP Mobbin token sheet (iOS home chrome)

enum WhoopIOSDesign {
    static let background = Color(hex: "#000000")
    static let card = Color(hex: "#1C1C1E")
    static let cardElevated = Color(hex: "#2C2C2E")
    static let cardBorder = Color(hex: "#3A3A3C")
    static let textSecondary = Color(hex: "#8E8E93")

    static let sleepBlue = Color(hex: "#6BA3D6")
    static let strainBlue = Color(hex: "#4DA3FF")
    static let strainBlueBright = Color(hex: "#E8F4FF")
    static let recoveryGreen = Color(hex: "#7CFF6B")
    static let recoveryYellow = Color(hex: "#FFD60A")
    static let recoveryRed = Color(hex: "#FF453A")
    static let stressHigh = Color(hex: "#FF9F0A")
    static let streakFlame = Color(hex: "#FF6B2C")

    static let fabGlowPurple = Color(hex: "#5E5CE6").opacity(0.55)
    static let fabGlowBlue = Color(hex: "#4DA3FF").opacity(0.45)

    static let ringSpring = Animation.spring(response: 0.85, dampingFraction: 0.82)
    static let cardAppear = Animation.easeOut(duration: 0.55)

    static func recoveryAccent(score: Double?) -> Color {
        guard let score else { return textSecondary }
        switch score {
        case 67...: return recoveryGreen
        case 34..<67: return recoveryYellow
        default: return recoveryRed
        }
    }

    static func strainGradient() -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [strainBlue, strainBlueBright, strainBlue]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
}

struct WhoopleWordmark: View {
    var size: CGFloat = 22

    var body: some View {
        Text(WhoopleBranding.wordmark)
            .font(.system(size: size, weight: .bold, design: .default))
            .tracking(size * 0.28)
            .foregroundStyle(StrandPalette.textPrimary)
    }
}

struct WhoopleMark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("W")
            .font(.system(size: size * 0.62, weight: .bold, design: .default))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
    }
}

/// Staggered card entrance (fade + slide up).
struct WhoopCardAppearModifier: ViewModifier {
    var index: Int
    var visible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .animation(
                WhoopIOSDesign.cardAppear.delay(Double(index) * 0.06),
                value: visible
            )
    }
}

extension View {
    func whoopCardAppear(index: Int, visible: Bool) -> some View {
        modifier(WhoopCardAppearModifier(index: index, visible: visible))
    }
}

#endif
