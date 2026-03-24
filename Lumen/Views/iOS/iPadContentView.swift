#if os(iOS)
import SwiftUI

struct iPadContentView: View {

    @Environment(AppStore.self) private var appStore
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var bindableStore = appStore
        NavigationSplitView(columnVisibility: $columnVisibility) {
            iPadSidebarPlaceholder()
                .navigationSplitViewColumnWidth(min: 260, ideal: LumenLayout.sidebarWidthMac)
        } detail: {
            iPadDetailPlaceholder()
        }
        .sheet(isPresented: $bindableStore.showingSettings) {
            Text("Settings — Phase 1")
                .padding()
        }
    }
}

private struct iPadSidebarPlaceholder: View {
    var body: some View {
        VStack(spacing: LumenSpacing.lg) {
            Spacer()
            Image(systemName: LumenIcon.chat)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
            Text("Conversations")
                .font(LumenType.headline)
                .foregroundStyle(.secondary)
            Text("Coming in Phase 1")
                .font(LumenType.footnote)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Lumen")
    }
}

private struct iPadDetailPlaceholder: View {
    var body: some View {
        VStack(spacing: LumenSpacing.xl) {
            Spacer()
            Image(systemName: "sparkle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: LumenSpacing.sm) {
                Text("Welcome to Lumen")
                    .font(LumenType.largeTitle)
                    .fontWeight(.bold)
                Text("Your private AI assistant")
                    .font(LumenType.messageBody)
                    .foregroundStyle(.secondary)
                Text("Full chat experience coming in Phase 1")
                    .font(LumenType.footnote)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: LumenLayout.maxContentWidthMac)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    iPadContentView()
        .environment(AppStore.shared)
}
#endif
