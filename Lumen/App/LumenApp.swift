import SwiftUI
import SwiftData
import CoreSpotlight

@main
struct LumenApp: App {

    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @State private var appStore = AppStore.shared
    @State private var chatStore = ChatStore.shared
    @State private var modelStore = ModelStore.shared
    @State private var libraryStore = LibraryStore.shared
    @State private var memoryStore = MemoryStore.shared

    @AppStorage("lumen.onboarding.completed") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if AppLaunchConfiguration.shouldSkipOnboarding || hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasSeenOnboarding: Binding(
                        get: { hasSeenOnboarding },
                        set: { hasSeenOnboarding = $0 }
                    ))
                }
            }
            .environment(appStore)
            .environment(chatStore)
            .environment(modelStore)
            .environment(libraryStore)
            .environment(memoryStore)
            .preferredColorScheme(appStore.resolvedColorScheme)
            .alert(item: Binding(
                get: { appStore.activeAlert },
                set: { appStore.activeAlert = $0 }
            )) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text(alert.dismissLabel)) {
                        alert.action?()
                    }
                )
            }
            .task {
                await ReleaseCaptureHarness.prepareIfNeeded()
                await modelStore.loadModels()
                ReleaseCaptureHarness.configureModelsIfNeeded()
                await chatStore.loadConversations()
                if chatStore.conversations.isEmpty {
                    await chatStore.createNewConversation()
                }
                if chatStore.currentModel == nil {
                    chatStore.currentModel = modelStore.selectedModel
                }
                await ReleaseCaptureHarness.presentIfNeeded()
            }
            .onOpenURL { url in
                Task { await DeepLinkHandler.shared.handle(url: url) }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                Task { await DeepLinkHandler.shared.handle(userActivity: activity) }
            }
        }
        .modelContainer(DataService.shared.modelContainer)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandMenu("Conversation") {
                Button("New Conversation") {
                    Task { @MainActor in
                        await ChatStore.shared.createNewConversation()
                    }
                }
            }
            #if targetEnvironment(macCatalyst)
            CommandGroup(after: .appSettings) {
                Button("Preferences...") { }
                    .keyboardShortcut(",", modifiers: .command)
            }
            #endif
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(appStore)
                .environment(chatStore)
                .environment(modelStore)
                .environment(libraryStore)
                .environment(memoryStore)
                .frame(minWidth: 450, minHeight: 300)
        }

        MenuBarExtra("Lumen", systemImage: "sparkle") {
            Button("Open Lumen") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("New Conversation") {
                Task { @MainActor in
                    await ChatStore.shared.createNewConversation()
                }
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        #endif
    }
}
