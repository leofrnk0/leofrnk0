import SwiftUI

struct LibraryView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Binding var selectedWorkout: Workout?
    @State private var showCreate   = false
    @State private var showSettings = false
    @State private var editingWorkout: Workout? = nil

    private var visibleWorkouts: [Workout] {
        store.filteredWorkouts.filter { settings.enabledSports.contains($0.sport) }
    }

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statsBar
                if visibleWorkouts.isEmpty { emptyState } else { workoutGrid }
            }
            .padding()
        }
        .background(Color.appBackground)
        .searchable(text: $store.searchText, prompt: "Search workouts…")
        .navigationTitle("TriWorkouts")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 4) {
                    settingsButton
                    if settings.isAdmin { createButton }
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 6) {
                    settingsButton
                    if settings.isAdmin { createButton }
                }
            }
            #endif
        }
        .sheet(isPresented: $showCreate) {
            CreateWorkoutView()
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(item: $editingWorkout) { workout in
            CreateWorkoutView(editingWorkout: workout)
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
        }
    }

    // MARK: - Subviews

    private var statsBar: some View {
        HStack(spacing: 12) {
            ForEach(Sport.allCases.filter { settings.enabledSports.contains($0) }, id: \.self) { sport in
                let count = visibleWorkouts.filter { $0.sport == sport }.count
                SportStatPill(sport: sport, count: count)
            }
            Spacer()
            Text("\(visibleWorkouts.count) Workouts")
                .font(.caption)
                .foregroundStyle(.tertiary)
            if store.activeFilterCount > 0 {
                Button("Reset") { store.clearFilters() }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.mutedOrange)
            }
        }
    }

    private var workoutGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 14)],
            spacing: 14
        ) {
            ForEach(visibleWorkouts) { workout in
                Button { selectedWorkout = workout } label: {
                    WorkoutCard(workout: workout, isSelected: selectedWorkout?.id == workout.id)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if settings.isAdmin {
                        Button { editingWorkout = workout } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            if selectedWorkout?.id == workout.id { selectedWorkout = nil }
                            store.deleteWorkout(workout)
                        } label: {
                            Label("Delete Workout", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40)).foregroundStyle(.tertiary)
            Text("No workouts found")
                .font(.headline).foregroundStyle(.secondary)
            Text("Adjust filters or search term")
                .font(.subheadline).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private var createButton: some View {
        Button { showCreate = true } label: { Image(systemName: "plus") }
    }

    private var settingsButton: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gearshape")
                .overlay(alignment: .topTrailing) {
                    if settings.isAdmin {
                        Circle().fill(Color.mutedOrange).frame(width: 7, height: 7)
                            .offset(x: 3, y: -3)
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
