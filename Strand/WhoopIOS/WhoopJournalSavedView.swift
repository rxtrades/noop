#if os(iOS)
import SwiftUI
import StrandDesign

/// Journal Saved success (GAP: green ring draw + check, "SAVED / Have a great day!").
struct WhoopJournalSavedView: View {
    var onDone: () -> Void

    @State private var ringProgress: CGFloat = 0
    @State private var checkScale: CGFloat = 0.4
    @State private var checkOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(WhoopIOSDesign.ringTrack, lineWidth: 6)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(WhoopIOSDesign.recoveryGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                        .scaleEffect(checkScale)
                        .opacity(checkOpacity)
                }
                VStack(spacing: 8) {
                    Text("SAVED")
                        .font(WhoopType.title(28))
                        .foregroundStyle(.white)
                    Text("Have a great day!")
                        .font(WhoopType.body(16))
                        .foregroundStyle(WhoopIOSDesign.textBody)
                }
                Button(action: onDone) {
                    Text("DONE")
                        .font(WhoopType.labelCaps(13))
                        .tracking(1.2)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.60)) { ringProgress = 1 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.45)) {
                checkScale = 1
                checkOpacity = 1
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

#endif
