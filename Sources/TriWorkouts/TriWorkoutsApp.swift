import SwiftUI

@main
struct TriWorkoutsApp: App {
    @State private var store    = WorkoutStore()
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(settings)
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 760)
        #endif
    }
}
