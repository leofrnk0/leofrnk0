import SwiftUI

struct LibraryView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var showFilter = false
    @State private var selectedWorkout: Workout?

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Stats bar
                statsBar

                // Grid
                if store.filteredWorkouts.isEmpty {
                    emptyState
                } else {
                    workoutGrid
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .searchable(text: $store.searchText, prompt: "Search workouts…")
        .navigationTitle("TriWorkouts")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                filterButton
            }
            #endif
        }
        .sheet(isPresented: $showFilter) {
            FilterView()
                .presentationDetents([.medium, .large])
        }
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            ForEach(Sport.allCases, id: \.self) { sport in
                let count = store.filteredWorkouts.filter { $0.sport == sport }.count
                SportStatPill(sport: sport, count: count)
            }
            Spacer()
            if store.activeFilterCount > 0 {
                Button("Clear") { store.clearFilters() }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var workoutGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)],
            spacing: 16
        ) {
            ForEach(store.filteredWorkouts) { workout in
                WorkoutCard(workout: workout)
                    .onTapGesture { selectedWorkout = workout }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No workouts found")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Try adjusting your filters or search term")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var filterButton: some View {
        Button {
            showFilter = true
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .overlay(alignment: .topTrailing) {
                    if store.activeFilterCount > 0 {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
        }
    }
}

private struct SportStatPill: View {
    let sport: Sport
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: sport.icon)
                .font(.caption)
                .foregroundStyle(sport.color)
            Text("\(count)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(sport.color.opacity(0.12), in: Capsule())
    }
}
