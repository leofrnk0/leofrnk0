import SwiftUI

@main
struct TriWorkoutsApp: App {
    @State private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 760)
        #endif
    }
}
