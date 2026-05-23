import SwiftUI
#if os(macOS)
import AppKit

// Handles activation policy before the run loop starts.
// Must be done in applicationWillFinishLaunching – the earliest safe
// point where NSApp is guaranteed to exist in an SPM executable.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}
#endif

@main
struct TriWorkoutsApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
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
                    DispatchQueue.main.async {
                        for window in NSApp.windows {
                            window.collectionBehavior = [.fullScreenPrimary, .managed]
                            window.styleMask.insert(.resizable)
                        }
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
