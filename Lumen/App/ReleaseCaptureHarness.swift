import Foundation

@MainActor
enum ReleaseCaptureHarness {
    private static var didPrepare = false
    private static var didPresent = false

    static func prepareIfNeeded() async {
        guard AppLaunchConfiguration.isReleaseCaptureMode, !didPrepare else { return }
        didPrepare = true

        UserDefaults.standard.set(true, forKey: "lumen.onboarding.completed")
        AppStore.shared.saveColorScheme(.dark)
        AppStore.shared.saveAllowOllamaLocal(false)
        AppStore.shared.saveAllowOllamaCloud(false)
        AppStore.shared.showingSettings = false
        AppStore.shared.activeAlert = nil

        MemoryStore.shared.clearAll()
        seedMemories()

        do {
            try await DataService.shared.deleteAllConversations()
            try await seedConversations()
        } catch {
            AppStore.shared.activeAlert = AppAlert(
                title: "Fixture Load Failed",
                message: error.localizedDescription
            )
        }
    }

    static func configureModelsIfNeeded() {
        guard AppLaunchConfiguration.isReleaseCaptureMode else { return }

        let model = AIModel.appleFoundationModel
        ModelStore.shared.availableModels = [model]
        ModelStore.shared.selectedModel = model
        ModelStore.shared.ollamaLocalConnectionStatus = .disabled
        ModelStore.shared.ollamaCloudConnectionStatus = .disabled
        ChatStore.shared.currentModel = model
        ChatStore.shared.agentModeEnabled = true
    }

    static func presentIfNeeded() async {
        guard AppLaunchConfiguration.isReleaseCaptureMode, !didPresent else { return }
        didPresent = true

        guard let scene = AppLaunchConfiguration.screenshotScene else { return }

        if let title = scene.targetConversationTitle,
           let conversation = ChatStore.shared.conversations.first(where: { $0.title == title }) {
            await ChatStore.shared.selectConversation(conversation)
        } else if let first = ChatStore.shared.conversations.first {
            await ChatStore.shared.selectConversation(first)
        }

        ChatStore.shared.conversationState = .idle
        ChatStore.shared.focusedMessageID = nil
        ChatStore.shared.pendingDocuments = []
        ChatStore.shared.pendingImageData = []
        ChatStore.shared.editingMessageID = nil
        AppStore.shared.showingSettings = scene.opensSettings
    }

    private static func seedMemories() {
        MemoryStore.shared.add(content: "Prefers concise executive summaries with clear tradeoffs.", category: .preference)
        MemoryStore.shared.add(content: "Lives in Portland and usually plans weekend trips by train.", category: .context)
        MemoryStore.shared.add(content: "Launching Lumen first on iPhone and iPad with privacy-first positioning.", category: .fact)
    }

    private static func seedConversations() async throws {
        _ = try await seedConversation(
            title: "Weekend in Portland",
            messages: [
                .init(
                    role: .user,
                    content: "Plan a Saturday in Portland that starts with coffee, includes Powell's, and ends with a quiet dinner.",
                    createdAt: fixtureDate(hoursAgo: 8)
                ),
                .init(
                    role: .assistant,
                    content: """
                    Here's a balanced Portland day plan:

                    1. Start at Proud Mary for coffee when it opens.
                    2. Walk the Pearl District and spend late morning at Powell's City of Books.
                    3. Have lunch at Maurice, then loop through the waterfront.
                    4. Keep the evening calm with dinner at Kann or Navarre, depending on whether you want something vibrant or intimate.
                    """,
                    createdAt: fixtureDate(hoursAgo: 7, minutesAgo: 45),
                    model: .appleFoundationModel
                ),
                .init(
                    role: .user,
                    content: "Add one rainy-day backup option and keep the budget under $150.",
                    createdAt: fixtureDate(hoursAgo: 7, minutesAgo: 30)
                ),
                .init(
                    role: .assistant,
                    content: """
                    Keep the rainy-day backup indoors at the Portland Art Museum and swap lunch to a lighter counter-service stop. With museum admission plus meals, you'll stay under your $150 cap while preserving the same pacing.
                    """,
                    createdAt: fixtureDate(hoursAgo: 7, minutesAgo: 10),
                    model: .appleFoundationModel
                )
            ],
            pinned: true
        )

        let releaseID = try await seedConversation(
            title: "Release Checklist",
            messages: [
                .init(
                    role: .user,
                    content: "Audit the launch blockers for Lumen before App Store submission.",
                    createdAt: fixtureDate(hoursAgo: 5)
                ),
                .init(
                    role: .assistant,
                    content: """
                    The main blockers are:

                    - Capture the final App Store screenshots from the release candidate.
                    - Publish the privacy policy and support URL.
                    - Verify the privacy questionnaire matches the app's on-device and optional Ollama behavior.
                    - Run a final TestFlight sanity pass before submission.
                    """,
                    createdAt: fixtureDate(hoursAgo: 4, minutesAgo: 45),
                    model: .appleFoundationModel
                ),
                .init(
                    role: .user,
                    content: "Call out any privacy-specific reviewer notes we should include.",
                    createdAt: fixtureDate(hoursAgo: 4, minutesAgo: 20)
                ),
                .init(
                    role: .assistant,
                    content: """
                    Include a short privacy note for App Review: Lumen supports on-device Apple Intelligence by default, keeps memory local to the device, and only connects to Ollama when the user explicitly enables a local server URL in Settings.
                    """,
                    createdAt: fixtureDate(hoursAgo: 4),
                    model: .appleFoundationModel
                )
            ]
        )

        let document = ImportedDocument(
            fileName: "Launch-Brief.md",
            extractedText: """
            Launch objective: ship a privacy-forward local AI assistant for iPhone and iPad.

            Critical requirements:
            - Publish App Store metadata and support materials.
            - Keep onboarding concise and premium.
            - Emphasize that Ollama remains optional and user-controlled.
            - Validate screenshots against Apple's 6.9-inch iPhone and 13-inch iPad classes.
            """,
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let composedPrompt = DocumentPromptComposer.compose(
            userText: "Summarize the launch brief and highlight the riskiest release items.",
            documents: [document]
        )

        _ = try await seedConversation(
            title: "Launch Brief Review",
            messages: [
                .init(
                    role: .user,
                    content: composedPrompt,
                    createdAt: fixtureDate(hoursAgo: 2, minutesAgo: 35)
                ),
                .init(
                    role: .assistant,
                    content: """
                    The brief is clear on positioning: Lumen should feel private, polished, and intentionally scoped.

                    Highest-risk release items:
                    - Missing screenshot capture from the exact release candidate
                    - Incomplete App Review notes around optional Ollama connectivity
                    - Any onboarding friction that makes the first-run experience feel unfinished
                    """,
                    createdAt: fixtureDate(hoursAgo: 2, minutesAgo: 12),
                    model: .appleFoundationModel
                )
            ]
        )

        let releaseConversation = try await DataService.shared.fetchConversation(id: releaseID)

        if let releaseConversation {
            try await DataService.shared.updateConversationSystemPrompt(
                id: releaseConversation.id,
                systemPrompt: "You are a senior iOS release engineer. Be concise, pragmatic, and reviewer-friendly."
            )
        }
    }

    private static func seedConversation(
        title: String,
        messages: [ChatMessage],
        pinned: Bool = false
    ) async throws -> UUID {
        let id = try await DataService.shared.createConversation(title: title)
        try await DataService.shared.addMessages(messages, to: id)
        if pinned {
            try await DataService.shared.toggleConversationPin(id: id)
        }
        return id
    }

    private static func fixtureDate(hoursAgo: Int, minutesAgo: Int = 0) -> Date {
        Date()
            .addingTimeInterval(TimeInterval(-hoursAgo * 3_600))
            .addingTimeInterval(TimeInterval(-minutesAgo * 60))
    }
}
