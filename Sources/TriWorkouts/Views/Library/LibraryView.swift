import SwiftUI

struct LibraryView: View {
    @Environment(WorkoutStore.self) private var store
    @Binding var selectedWorkout: Workout?
    @State private var showFilter = false

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statsBar

                if store.filteredWorkouts.isEmpty {
                    emptyState
                } else {
                    workoutGrid
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .searchable(text: $store.searchText, prompt: "Workouts suchen…")
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
    }

    // MARK: - Subviews

    private var statsBar: some View {
        HStack(spacing: 12) {
            ForEach(Sport.allCases, id: \.self) { sport in
                let count = store.filteredWorkouts.filter { $0.sport == sport }.count
                SportStatPill(sport: sport, count: count)
            }
            Spacer()
            Text("\(store.filteredWorkouts.count) Workouts")
                .font(.caption)
                .foregroundStyle(.tertiary)
            if store.activeFilterCount > 0 {
                Button("Zurücksetzen") { store.clearFilters() }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
    }

    private var workoutGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 14)],
            spacing: 14
        ) {
            ForEach(store.filteredWorkouts) { workout in
                Button {
                    selectedWorkout = workout
                } label: {
                    WorkoutCard(workout: workout, isSelected: selectedWorkout?.id == workout.id)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("Keine Workouts gefunden")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Filter oder Suchbegriff anpassen")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var filterButton: some View {
        Button { showFilter = true } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .overlay(alignment: .topTrailing) {
                    if store.activeFilterCount > 0 {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
        }
    }
}

// MARK: - Sport stat pill

private struct SportStatPill: View {
    let sport: Sport
    let count: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: sport.icon).font(.caption2).foregroundStyle(sport.color)
            Text("\(count)").font(.caption.monospacedDigit().weight(.semibold)).foregroundStyle(.primary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(sport.color.opacity(0.12), in: Capsule())
    }
}
