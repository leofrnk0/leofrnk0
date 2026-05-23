import SwiftUI

struct ContentView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var selectedWorkout: Workout?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            FilterView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } content: {
            LibraryView(selectedWorkout: $selectedWorkout)
                .navigationSplitViewColumnWidth(min: 300, ideal: 420)
        } detail: {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout, onDeleted: { selectedWorkout = nil })
            } else {
                emptyDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
        #else
        if sizeClass == .regular {
            // iPad: full three-column split view
            NavigationSplitView {
                FilterView()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
            } content: {
                LibraryView(selectedWorkout: $selectedWorkout)
            } detail: {
                if let workout = selectedWorkout {
                    WorkoutDetailView(workout: workout, onDeleted: { selectedWorkout = nil })
                } else {
                    emptyDetail
                }
            }
            .navigationSplitViewStyle(.balanced)
        } else {
            // iPhone: single-column stack
            NavigationStack {
                LibraryView(selectedWorkout: $selectedWorkout)
                    .navigationDestination(item: $selectedWorkout) { workout in
                        WorkoutDetailView(workout: workout)
                    }
            }
        }
        #endif
    }

    private var emptyDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Select a Workout")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tap a workout to see all details.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
