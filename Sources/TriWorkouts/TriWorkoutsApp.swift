import SwiftUI
#if os(macOS)
import AppKit
#endif

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
                #if os(macOS)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        window.collectionBehavior = [.fullScreenPrimary, .managed]
                        window.styleMask.insert(.resizable)
                    }
                }
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 760)
        #endif
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}
