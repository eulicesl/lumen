import SwiftUI

struct ContentView: View {

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(iOS)
        if horizontalSizeClass == .regular {
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
