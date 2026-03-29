import SwiftUI

struct ContentView: View {

    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadContentView()
        } else {
            MainTabView()
        }
        #elseif os(macOS)
        MacContentView()
        #endif
    }
}

#Preview {
    ContentView()
        .environment(AppStore.shared)
}
