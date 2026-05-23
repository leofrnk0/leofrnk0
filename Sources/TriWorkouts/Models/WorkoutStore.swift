import Foundation
import Observation

@Observable
final class WorkoutStore {
    private var bundleWorkouts: [Workout] = []
    private(set) var userWorkouts: [Workout] = []
    var searchText: String = ""
    var selectedSports: Set<Sport> = []
    var selectedTags: Set<WorkoutTag> = []

    private let userDefaultsKey = "userWorkouts_v1"

    init() {
        loadBundleWorkouts()
        loadUserWorkouts()
    }

    // MARK: - Combined list (user workouts override bundle by ID)

    var workouts: [Workout] {
        let userIDs = Set(userWorkouts.map(\.id))
        return userWorkouts + bundleWorkouts.filter { !userIDs.contains($0.id) }
    }

    var filteredWorkouts: [Workout] {
        workouts.filter { w in
            let sport  = selectedSports.isEmpty || selectedSports.contains(w.sport)
            let tags   = selectedTags.isEmpty   || w.tags.contains(where: { selectedTags.contains($0) })
            let search = searchText.isEmpty     || w.name.localizedCaseInsensitiveContains(searchText)
                                                || w.description.localizedCaseInsensitiveContains(searchText)
            return sport && tags && search
        }
    }

    var activeFilterCount: Int { selectedSports.count + selectedTags.count }

    // MARK: - User workout management

    func addWorkout(_ workout: Workout) {
        userWorkouts.insert(workout, at: 0)
        saveUserWorkouts()
    }

    func updateWorkout(_ workout: Workout) {
        if let idx = userWorkouts.firstIndex(where: { $0.id == workout.id }) {
            userWorkouts[idx] = workout
        } else {
            userWorkouts.insert(workout, at: 0)
        }
        saveUserWorkouts()
    }

    func deleteWorkout(_ workout: Workout) {
        userWorkouts.removeAll { $0.id == workout.id }
        saveUserWorkouts()
    }

    func isUserWorkout(_ workout: Workout) -> Bool {
        userWorkouts.contains(where: { $0.id == workout.id })
    }

    // MARK: - Filter actions

    func toggleSport(_ sport: Sport) {
        if selectedSports.contains(sport) { selectedSports.remove(sport) }
        else { selectedSports.insert(sport) }
    }

    func toggleTag(_ tag: WorkoutTag) {
        if selectedTags.contains(tag) { selectedTags.remove(tag) }
        else { selectedTags.insert(tag) }
    }

    func clearFilters() {
        selectedSports.removeAll()
        selectedTags.removeAll()
        searchText = ""
    }

    // MARK: - Persistence

    private func loadBundleWorkouts() {
        guard let url = Bundle.module.url(forResource: "workouts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        bundleWorkouts = (try? JSONDecoder().decode([Workout].self, from: data)) ?? []
    }

    private func loadUserWorkouts() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        userWorkouts = (try? JSONDecoder().decode([Workout].self, from: data)) ?? []
    }

    private func saveUserWorkouts() {
        guard let data = try? JSONEncoder().encode(userWorkouts) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
