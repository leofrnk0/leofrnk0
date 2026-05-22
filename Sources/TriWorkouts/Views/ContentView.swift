import SwiftUI

struct ContentView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var selectedWorkout: Workout?

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
                WorkoutDetailView(workout: workout)
            } else {
                emptyDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
        #else
        NavigationStack {
            LibraryView(selectedWorkout: $selectedWorkout)
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutDetailView(workout: workout)
                }
        }
        #endif
    }

    private var emptyDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("Workout auswählen")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tippe auf ein Workout um alle Details zu sehen.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
