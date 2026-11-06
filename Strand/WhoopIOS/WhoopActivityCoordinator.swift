#if os(iOS)
import SwiftUI
import StrandDesign

/// Picker → Start sheet → Live Activity orchestration for Whoople chrome.
struct WhoopActivityCoordinator: View {
    var mode: Mode = .start

    enum Mode { case start, add }

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var sport: String?
    @State private var showStart = false
    @State private var showLive = false
    @State private var showPicker = true

    var body: some View {
        Group {
            if showLive {
                WhoopLiveActivityView()
            } else {
                WhoopActivityPickerView(title: mode == .start ? "Start Activity" : "Add Activity") { name in
                    sport = name
                    showPicker = false
                    if mode == .start {
                        showStart = true
                    } else {
                        model.startWorkout(sport: name)
                        showLive = true
                    }
                }
            }
        }
        .sheet(isPresented: $showStart) {
            if let sport {
                WhoopStartActivitySheet(
                    sport: sport,
                    onStart: { _ in
                        showStart = false
                        model.startWorkout(sport: sport)
                        showLive = true
                    },
                    onChangeSport: {
                        showStart = false
                        showPicker = true
                        self.sport = nil
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .onChange(of: model.activeWorkout) { _, w in
            if w == nil, showLive {
                // Session ended/discarded from live view — leave live chrome up until
                // WhoopLiveActivityView dismisses itself (detail sheet or Done).
            }
        }
        .preferredColorScheme(.dark)
    }
}

#endif
