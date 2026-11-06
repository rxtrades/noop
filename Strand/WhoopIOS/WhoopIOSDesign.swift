#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Whoople Phase 1 tokens (Mobbin-sampled WHOOP chrome; brand stays Whoople)

enum WhoopIOSDesign {
    // Background gradient stops (GAP §2)
    static let bgTop = Color(hex: "#263135")
    static let bgMid = Color(hex: "#191E22")
    static let bgBase = Color(hex: "#111619")
    static let bgBottom = Color(hex: "#030504")
    /// Flat fallback / deep canvas after the gradient band.
    static let background = bgBottom

    static let card = Color(hex: "#1F2427")
    static let cardRaised = Color(hex: "#2B2F32")
    static let cardElevated = Color(hex: "#2B2F32")
    static let surfaceList = Color(hex: "#29343A")
    static let tabBarFill = Color(hex: "#2E2E2E")
    static let cardBorder = Color(hex: "#3A4248").opacity(0.55)
    static let ringTrack = Color(hex: "#2A3238")
    static let gridLine = Color(hex: "#2A3238")

    static let textPrimary = Color.white
    static let textBody = Color(hex: "#C9CED2")
    static let textSecondary = Color(hex: "#8A9399")
    static let textTertiary = Color(hex: "#5E676D")

    static let sleepBlue = Color(hex: "#7BA1BB")
    static let strainBlue = Color(hex: "#0093E7")
    static let recoveryGreen = Color(hex: "#16EC06")
    static let recoveryYellow = Color(hex: "#ECA800")
    static let recoveryRed = Color(hex: "#D4001C")
    static let stressHigh = Color(hex: "#FF9F0A")
    static let streakFlame = Color(hex: "#FF6B2C")
    static let trendDown = Color(hex: "#FF9F0A")
    static let trendUp = Color(hex: "#16EC06")
    static let mint = Color(hex: "#00F0A0")
    static let rangeBand = Color(hex: "#88D0F0").opacity(0.15)

    static let fabGlowPurple = Color(hex: "#5E5CE6").opacity(0.55)
    static let fabGlowBlue = Color(hex: "#0093E7").opacity(0.45)

    // Rings (GAP §2)
    static let homeRingDiameter: CGFloat = 88
    static let homeRingLineWidth: CGFloat = 6
    static let homeRingGap: CGFloat = 28
    static let detailRingDiameter: CGFloat = 230
    static let detailRingLineWidth: CGFloat = 20
    static let miniRingDiameter: CGFloat = 20
    static let miniRingLineWidth: CGFloat = 3

    static let cardRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardGap: CGFloat = 8
    static let sectionGap: CGFloat = 24
    static let pageMargin: CGFloat = 16
    static let rowHeight: CGFloat = 56

    /// Ring fill + count-up (GAP motion).
    static let ringFill = Animation.easeOut(duration: 0.80)
    static let ringSpring = Animation.easeOut(duration: 0.80)
    static let cardAppear = Animation.easeOut(duration: 0.55)
    static let sheetSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)

    static func recoveryAccent(score: Double?) -> Color {
        guard let score else { return textSecondary }
        switch score {
        case 67...: return recoveryGreen
        case 34..<67: return recoveryYellow
        default: return recoveryRed
        }
    }

    /// Legacy helper — Phase 1 uses solid strain blue (no gradient on rings).
    static func strainGradient() -> AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [strainBlue, strainBlue]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    static var pageBackground: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: bgTop, location: 0),
                .init(color: Color(hex: "#20272D"), location: 0.18),
                .init(color: bgMid, location: 0.35),
                .init(color: Color(hex: "#12171B"), location: 0.52),
                .init(color: bgBase, location: 0.72),
                .init(color: bgBottom, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Type scale (GAP §2)

enum WhoopType {
    static func hero(_ size: CGFloat = 64) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func metric(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func ringValue(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title(_ size: CGFloat = 22) -> Font { .system(size: size, weight: .bold) }
    static func cardTitle(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular) }
    static func rowCaps(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .semibold) }
    static func labelCaps(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .semibold) }
    static func caption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .medium) }
    static func tab(_ size: CGFloat = 10) -> Font { .system(size: size, weight: .medium) }
    static let rowTracking: CGFloat = 1.2
    static let labelTracking: CGFloat = 1.5
}

struct WhoopleWordmark: View {
    var size: CGFloat = 18

    var body: some View {
        Text(WhoopleBranding.wordmark)
            .font(.system(size: size, weight: .light, design: .default))
            .tracking(3)
            .foregroundStyle(WhoopIOSDesign.textPrimary)
    }
}

struct WhoopleMark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("W")
            .font(.system(size: size * 0.52, weight: .bold, design: .default))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
    }
}

struct WhoopCardAppearModifier: ViewModifier {
    var index: Int
    var visible: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .animation(WhoopIOSDesign.cardAppear.delay(Double(index) * 0.06), value: visible)
    }
}

struct WhoopPageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                WhoopIOSDesign.pageBackground
                    .ignoresSafeArea()
            )
    }
}

extension View {
    func whoopCardAppear(index: Int, visible: Bool) -> some View {
        modifier(WhoopCardAppearModifier(index: index, visible: visible))
    }
    func whoopPageBackground() -> some View {
        modifier(WhoopPageBackground())
    }
}

#endif
