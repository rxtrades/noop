#if os(iOS)
import SwiftUI
import StrandDesign

/// App Settings list (Mobbin 134) + AI Settings with Coach API key (Mobbin 131 / Phase 9 pull-forward).
struct WhoopAppSettingsView: View {
    @AppStorage("noop.whoopHomeEnabled") private var whoopHomeEnabled = true
    @AppStorage("noop.coachEnabled") private var coachEnabled = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                navRow("ACTIVITY SETTINGS", "heart.text.square")
                NavigationLink {
                    WhoopCoachAPIKeySettingsView()
                } label: {
                    rowLabel("AI SETTINGS", "sparkles")
                }
                .buttonStyle(.plain)
                navRow("DATA EXPORT", "square.and.arrow.down")
                navRow("INTEGRATIONS", "link")
                navRow("JOURNAL", "list.clipboard")
                navRow("NOTIFICATIONS", "bell")
                navRow("HORMONAL INSIGHTS", "drop")
                navRow("HIDE METRICS", "eye.slash")

                Text("WHOOPLE")
                    .font(WhoopType.rowCaps(12))
                    .tracking(1)
                    .foregroundStyle(WhoopIOSDesign.textSecondary)
                    .padding(.top, 14)

                WhoopCard {
                    Toggle(isOn: $whoopHomeEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Whoople chrome")
                                .font(WhoopType.cardTitle(16))
                                .foregroundStyle(.white)
                            Text("Home / Health / Community / floating bar")
                                .font(WhoopType.caption(12))
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                    .tint(WhoopIOSDesign.recoveryGreen)
                }

                WhoopCard {
                    Toggle(isOn: $coachEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Coach")
                                .font(WhoopType.cardTitle(16))
                                .foregroundStyle(.white)
                            Text("Master switch for chat + briefs")
                                .font(WhoopType.caption(12))
                                .foregroundStyle(WhoopIOSDesign.textSecondary)
                        }
                    }
                    .tint(WhoopIOSDesign.recoveryGreen)
                    .onChange(of: coachEnabled) { _, on in
                        CoachBriefScheduler.applyMasterSwitch(on)
                    }
                }
            }
            .padding(WhoopIOSDesign.pageMargin)
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("APP SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.2)
                    .foregroundStyle(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func navRow(_ title: String, _ icon: String) -> some View {
        rowLabel(title, icon)
    }

    private func rowLabel(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(WhoopIOSDesign.textSecondary)
                .frame(width: 28, alignment: .center)
            Text(title)
                .font(WhoopType.rowCaps(13))
                .tracking(0.8)
                .foregroundStyle(.white)
            Spacer(minLength: 0)
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
}

/// AI Settings (Mobbin 131) + Coach API key — moved out of Coach tab / W sheet into Settings.
struct WhoopCoachAPIKeySettingsView: View {
    @EnvironmentObject private var coach: AICoachEngine
    @AppStorage("noop.coachMemoryEnabled") private var memoryEnabled = true
    @State private var keyDraft = ""
    @State private var status = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEMORY")
                            .font(WhoopType.cardTitle(17))
                            .foregroundStyle(.white)
                        Text("Allow Coach to remember details from past conversations to provide personalized guidance. Memory stays on this device with your brief history.")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                    }
                    Toggle("", isOn: $memoryEnabled)
                        .labelsHidden()
                        .tint(WhoopIOSDesign.recoveryGreen)
                }

                Rectangle()
                    .fill(WhoopIOSDesign.textTertiary.opacity(0.35))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                WhoopCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Data privacy")
                            .font(WhoopType.cardTitle(16))
                            .foregroundStyle(.white)
                        Text("We exist to improve your life, not invade it. You control your personal data. Coach only leaves the device when you send a chat turn with your own API key.")
                            .font(WhoopType.body(14))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        HStack(spacing: 6) {
                            Text("LEARN MORE")
                                .font(WhoopType.labelCaps(12))
                                .tracking(1)
                                .foregroundStyle(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 4)
                    }
                }

                WhoopCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PROVIDER")
                            .font(WhoopType.rowCaps(12))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        Picker("Provider", selection: $coach.provider) {
                            ForEach(AIProvider.allCases) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(coach.hasKey ? "KEY ON FILE" : "API KEY")
                            .font(WhoopType.rowCaps(12))
                            .foregroundStyle(WhoopIOSDesign.textSecondary)
                        SecureField("Paste API key", text: $keyDraft)
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(WhoopIOSDesign.cardRaised))

                        Button {
                            let t = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !t.isEmpty else { return }
                            coach.setKey(t)
                            keyDraft = ""
                            status = "Saved"
                        } label: {
                            Text("SAVE KEY")
                                .font(WhoopType.labelCaps(13))
                                .tracking(1)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white))
                        }
                        .buttonStyle(.plain)

                        if coach.hasKey {
                            Button {
                                coach.clearKey()
                                status = "Cleared"
                            } label: {
                                Text("Remove key")
                                    .font(WhoopType.body(14))
                                    .foregroundStyle(WhoopIOSDesign.stressHigh)
                            }
                            .buttonStyle(.plain)
                        }

                        if !status.isEmpty {
                            Text(status)
                                .font(WhoopType.caption(12))
                                .foregroundStyle(WhoopIOSDesign.recoveryGreen)
                        }
                    }
                }
            }
            .padding(WhoopIOSDesign.pageMargin)
            .padding(.bottom, 40)
        }
        .whoopPageBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI SETTINGS")
                    .font(WhoopType.labelCaps(13))
                    .tracking(1.2)
                    .foregroundStyle(.white)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#endif
