import SwiftUI
import StrandDesign

/// First-run acknowledgment gate (clickwrap). Shown over EVERYTHING — before onboarding, pairing, or
/// any Bluetooth access — until the current `Terms.currentVersion` is accepted, and again if the
/// terms materially change. The user must tick the (un-pre-checked) box and tap Accept; the accepted
/// version is then stored locally, the on-device equivalent of a consent record. See `Terms` / `TERMS.md`.
struct TermsGateView: View {
    let onAccept: () -> Void
    /// One flag per `Terms.attestations` entry; every one must be ticked before Accept enables.
    @State private var checks: [Bool] = Array(repeating: false, count: Terms.attestations.count)
    #if os(iOS)
    @AppStorage("noop.whoopHomeEnabled") private var whoopHomeEnabled = true
    @State private var scrolledFar = false
    #endif

    private var allChecked: Bool { checks.allSatisfy { $0 } }

    var body: some View {
        #if os(iOS)
        if whoopHomeEnabled {
            whoopleBody
        } else {
            classicBody
        }
        #else
        classicBody
        #endif
    }

    #if os(iOS)
    private var whoopleBody: some View {
        ZStack {
            WhoopIOSDesign.pageBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("BEFORE YOU USE \(ProductBrand.displayName.uppercased())")
                        .font(WhoopType.title(22))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("Please read the points below, then confirm each statement.")
                        .font(WhoopType.body(14))
                        .foregroundStyle(WhoopIOSDesign.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                .padding(.bottom, 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Terms.points, id: \.0) { point in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Self.branded(point.0))
                                    .font(WhoopType.cardTitle(16))
                                    .foregroundStyle(.white)
                                Text(Self.branded(point.1))
                                    .font(WhoopType.body(14))
                                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Rectangle()
                            .fill(WhoopIOSDesign.cardBorder)
                            .frame(height: 1)
                            .padding(.vertical, 2)

                        Text("Please confirm each of these:")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)

                        ForEach(Array(Terms.attestations.enumerated()), id: \.offset) { idx, line in
                            Toggle(isOn: Binding(get: { checks[idx] }, set: { checks[idx] = $0 })) {
                                Text(Self.branded(line))
                                    .font(WhoopType.body(14))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .tint(WhoopIOSDesign.recoveryGreen)
                        }

                        Text("The full terms are in TERMS.md, shipped with \(ProductBrand.displayName). This is not legal advice.")
                            .font(WhoopType.caption(12))
                            .foregroundStyle(WhoopIOSDesign.textTertiary)
                            .padding(.top, 2)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: TermsScrollBottomKey.self,
                                        value: geo.frame(in: .named("termsScroll")).maxY
                                    )
                                }
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .coordinateSpace(name: "termsScroll")
                .onPreferenceChange(TermsScrollBottomKey.self) { maxY in
                    // Enable once the user has scrolled near the end (or content already fits).
                    if maxY < 780 { scrolledFar = true }
                }
                .onAppear {
                    // Short terms that fit without scrolling should still unlock after a beat.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if !scrolledFar { scrolledFar = true }
                    }
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

                Button(action: onAccept) {
                    Text("ACCEPT & CONTINUE")
                        .font(WhoopType.labelCaps(14))
                        .tracking(1.2)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
                .disabled(!(allChecked && scrolledFar))
                .opacity((allChecked && scrolledFar) ? 1 : 0.30)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
    #endif

    private var classicBody: some View {
        ZStack {
            StrandPalette.surfaceBase.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("Before you use \(ProductBrand.displayName)")
                        .font(StrandFont.title1)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text("Please read the points below, then confirm each statement.")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 36)
                .padding(.bottom, 22)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(Terms.points, id: \.0) { point in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Self.branded(point.0))
                                    .font(StrandFont.headline)
                                    .foregroundStyle(StrandPalette.textPrimary)
                                Text(Self.branded(point.1))
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(StrandPalette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Rectangle()
                            .fill(StrandPalette.hairline)
                            .frame(height: 1)
                            .padding(.vertical, 2)

                        Text("Please confirm each of these:")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)

                        ForEach(Array(Terms.attestations.enumerated()), id: \.offset) { idx, line in
                            Toggle(isOn: Binding(get: { checks[idx] }, set: { checks[idx] = $0 })) {
                                Text(Self.branded(line))
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(StrandPalette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            #if os(macOS)
                            .toggleStyle(.checkbox)
                            #endif
                        }

                        Text("The full terms are in TERMS.md, shipped with \(ProductBrand.displayName). This is not legal advice.")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 18)
                }
                #if os(iOS)
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                #endif

                Rectangle()
                    .fill(StrandPalette.hairline)
                    .frame(height: 1)

                Button(action: onAccept) {
                    Text("Accept & Continue")
                        .font(StrandFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .tint(StrandPalette.accent)
                .disabled(!allChecked)
                .keyboardShortcut(.defaultAction)
                .padding(26)
            }
            .frame(maxWidth: 560, maxHeight: 720)
        }
    }

    /// Phase 0: show Whoople on iOS while shared copy still keys off "NOOP".
    private static func branded(_ text: String) -> String {
        text.replacingOccurrences(of: "NOOP", with: ProductBrand.displayName)
    }
}

#if os(iOS)
private struct TermsScrollBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}
#endif
