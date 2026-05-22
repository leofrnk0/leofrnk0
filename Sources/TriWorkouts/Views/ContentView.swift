import SwiftUI

struct ContentView: View {
    @Environment(WorkoutStore.self) private var store

    var body: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: .constant(.all)) {
            FilterView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            LibraryView()
        }
        .navigationSplitViewStyle(.balanced)
        #else
        NavigationStack {
            LibraryView()
        }
        #endif
    }
}
