import SwiftUI
import AppKit

@main
struct TriWorkoutsApp: App {
    @State private var store    = WorkoutStore()
    @State private var settings = AppSettings()

    init() {
        // Without this, SPM executables run as background/accessory processes:
        // no Dock icon, no foreground activation, no fullscreen support.
        // NSApp (the global) is nil until NSApplication is created; .shared
        // creates it if needed, avoiding the nil-unwrap crash on startup.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(settings)
                .preferredColorScheme(.dark)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    DispatchQueue.main.async {
                        for window in NSApp.windows {
                            window.collectionBehavior = [.fullScreenPrimary, .managed]
                            window.styleMask.insert(.resizable)
                        }
                    }
                }
        }
        .defaultSize(width: 1200, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}
