import SwiftUI
import AppKit

// Handles activation policy before the run loop starts.
// Must be done in applicationWillFinishLaunching – the earliest safe
// point where NSApp is guaranteed to exist in an SPM executable.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

@main
struct TriWorkoutsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store    = WorkoutStore()
    @State private var settings = AppSettings()

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
