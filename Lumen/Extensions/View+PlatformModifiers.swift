import SwiftUI

// Platform-conditional view modifiers used across multiple Shared views.
// Each wraps an iOS-only SwiftUI API so call sites stay readable on both platforms.

extension View {
    @ViewBuilder
    func navigationBarInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func insetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self.listStyle(.inset)
        #endif
    }
}
