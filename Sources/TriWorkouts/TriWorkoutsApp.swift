import SwiftUI

@main
struct TriWorkoutsApp: App {
    @State private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        #endif
    }
}
