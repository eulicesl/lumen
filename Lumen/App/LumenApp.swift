import SwiftUI
import SwiftData

@main
struct LumenApp: App {

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @State private var appStore = AppStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appStore)
        }
        .modelContainer(DataService.shared.modelContainer)

        #if os(macOS)
        MenuBarExtra("Lumen", systemImage: "sparkle") {
            Button("Open Lumen") {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        #endif
    }
}
