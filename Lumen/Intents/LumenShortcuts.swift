import AppIntents

// MARK: - AppShortcutsProvider
// Registers Siri phrase patterns so users can say things like:
//   "Ask Lumen [query]"
//   "Start a new Lumen conversation"
//   "Summarize my last Lumen conversation"
//
// Xcode: add this file to the main Lumen target.
// The $applicationName token is replaced with "Lumen" automatically.

struct LumenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskLumenIntent(),
            phrases: [
                "Ask \(.applicationName) \(\.$query)",
                "Send \(\.$query) to \(.applicationName)",
                "Question for \(.applicationName): \(\.$query)",
            ],
            shortTitle: "Ask Lumen",
            systemImageName: "sparkle"
        )

        AppShortcut(
            intent: StartConversationIntent(),
            phrases: [
                "New \(.applicationName) conversation",
                "Start a \(.applicationName) chat",
                "Open \(.applicationName)",
            ],
            shortTitle: "New Conversation",
            systemImageName: "plus.bubble"
        )

        AppShortcut(
            intent: SummarizeConversationIntent(),
            phrases: [
                "Summarize my last \(.applicationName) conversation",
                "\(.applicationName) summary",
            ],
            shortTitle: "Summarize Conversation",
            systemImageName: "text.quote"
        )
    }
}
