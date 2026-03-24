import SwiftUI

struct ContentView: View {

    var body: some View {
        #if os(iOS)
        MainTabView()
        #elseif os(macOS)
        MacContentView()
        #endif
    }
}

#Preview {
    ContentView()
        .environment(AppStore.shared)
}
