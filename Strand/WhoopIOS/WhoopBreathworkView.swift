#if os(iOS)
import SwiftUI
import StrandDesign

/// Breathwork intro (Mobbin 104) → existing BreathingView session.
struct WhoopBreathworkView: View {
    @State private var startSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(WhoopIOSDesign.sleepBlue.opacity(0.35), lineWidth: 2)
                        .frame(width: 180, height: 180)
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 64, weight: .ultraLight))
                        .foregroundStyle(WhoopIOSDesign.sleepBlue)
                }
                .padding(.top, 24)

                Text("BREATHWORK")
                    .font(WhoopType.title(28))
                    .foregroundStyle(.white)

                Text("Slow your breathing to drop stress and support recovery. Guided sessions use the same breath engine you already have.")
                    .font(WhoopType.body(15))
                    .foregroundStyle(WhoopIOSDesign.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                WhoopCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INCREASE ALERTNESS")
                            .font(WhoopType.rowCaps(12))
                            .tracking(0.8)
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        Text("Box breathing · 4 rounds")
                            .font(WhoopType.cardTitle(16))
                            .foregroundStyle(.white)
                        Text("Inhale 4 · Hold 4 · Exhale 4 · Hold 4")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.textBody)
                    }
                }
                .padding(.horizontal, WhoopIOSDesign.pageMargin)

                Button { startSession = true } label: {
                    Text("START BREATHWORK")
                        .font(WhoopType.labelCaps(14))
                        .tracking(1.2)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, WhoopIOSDesign.pageMargin)
            }
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationTitle("Breathwork")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $startSession) {
            BreathingView()
        }
    }
}

#endif
