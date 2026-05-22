import Foundation
import Observation

@Observable
final class WorkoutStore {
    var workouts: [Workout] = []
    var searchText: String = ""
    var selectedSports: Set<Sport> = []
    var selectedTags: Set<WorkoutTag> = []

    init() { loadWorkouts() }

    var filteredWorkouts: [Workout] {
        workouts.filter { w in
            let sport   = selectedSports.isEmpty || selectedSports.contains(w.sport)
            let tags    = selectedTags.isEmpty   || w.tags.contains(where: { selectedTags.contains($0) })
            let search  = searchText.isEmpty     || w.name.localizedCaseInsensitiveContains(searchText)
                                                 || w.description.localizedCaseInsensitiveContains(searchText)
            return sport && tags && search
        }
    }

    var activeFilterCount: Int {
        selectedSports.count + selectedTags.count
    }

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

    private func loadWorkouts() {
        guard let url = Bundle.main.url(forResource: "workouts", withExtension: "json") else {
            assertionFailure("workouts.json not found in bundle")
            return
        }
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        workouts = (try? decoder.decode([Workout].self, from: data)) ?? []
    }
}
