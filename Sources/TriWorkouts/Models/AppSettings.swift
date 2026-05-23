import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {

    // MARK: - Sports preference (persisted)

    var enabledSports: Set<Sport> {
        didSet { saveSports() }
    }

    func toggleSport(_ sport: Sport) {
        if enabledSports.contains(sport) {
            guard enabledSports.count > 1 else { return }
            enabledSports.remove(sport)
        } else {
            enabledSports.insert(sport)
        }
    }

    // MARK: - Admin state (in-memory only, resets on launch)

    private(set) var isAdmin = false

    func login(pin: String) -> Bool {
        guard pin == storedPin else { return false }
        isAdmin = true
        return true
    }

    func logout() { isAdmin = false }

    func changePin(to newPin: String) {
        UserDefaults.standard.set(newPin, forKey: pinKey)
    }

    var storedPin: String {
        UserDefaults.standard.string(forKey: pinKey) ?? "1234"
    }

    // MARK: - Init

    init() {
        if let data = UserDefaults.standard.data(forKey: sportsKey),
           let decoded = try? JSONDecoder().decode(Set<Sport>.self, from: data) {
            enabledSports = decoded
        } else {
            enabledSports = Set(Sport.allCases)
        }
    }

    // MARK: - Persistence

    private let sportsKey = "enabledSports_v1"
    private let pinKey    = "adminPin_v1"

    private func saveSports() {
        guard let data = try? JSONEncoder().encode(enabledSports) else { return }
        UserDefaults.standard.set(data, forKey: sportsKey)
    }
}
