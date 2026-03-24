import SwiftUI

#if os(macOS)
struct MacContentView: View {

    @Environment(AppStore.self) private var appStore
    @State private var selectedItem: String? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(columnVisibility)) {
            MacSidebarPlaceholder()
                .navigationSplitViewColumnWidth(min: 220, ideal: LumenLayout.sidebarWidthMac)
        } detail: {
            MacDetailPlaceholder()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(LumenAnimation.standard) {
                        if columnVisibility == .all {
                            columnVisibility = .detailOnly
                        } else {
                            columnVisibility = .all
                        }
                    }
                } label: {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                } label: {
                    Label("New Conversation", systemImage: LumenIcon.newChat)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appStore.showingSettings = true
                } label: {
                    Label("Settings", systemImage: LumenIcon.settings)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .sheet(isPresented: .constant(appStore.showingSettings)) {
            Text("Settings — Phase 1")
                .padding()
        }
    }
}

private struct MacSidebarPlaceholder: View {
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

private struct MacDetailPlaceholder: View {
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
    MacContentView()
        .environment(AppStore.shared)
        .frame(width: 900, height: 600)
}
#endif
