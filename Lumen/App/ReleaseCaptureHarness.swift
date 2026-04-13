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
        MemoryStore.shared.add(content: "Prefers concise plans with clear tradeoffs and one standout recommendation.", category: .preference)
        MemoryStore.shared.add(content: "Usually plans city weekends around walkable neighborhoods, bookstores, and good coffee.", category: .context)
        MemoryStore.shared.add(content: "Uses Lumen for travel planning, document summaries, and thoughtful writing help.", category: .fact)
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

        let kyotoID = try await seedConversation(
            title: "Kyoto Trip Ideas",
            messages: [
                .init(
                    role: .user,
                    content: "Plan three calm days in Kyoto with a vegetarian-friendly neighborhood, one temple morning, and a small design museum.",
                    createdAt: fixtureDate(hoursAgo: 5)
                ),
                .init(
                    role: .assistant,
                    content: """
                    I'd center the trip around Higashiyama or northern Gion. Both feel walkable, photogenic, and give you easy access to temple mornings plus several vegetarian-friendly dinners nearby.

                    Suggested structure:
                    - Day 1: Settle into Higashiyama, visit Kiyomizu-dera early, then keep the evening slow with shojin ryori or a modern vegetarian tasting menu.
                    - Day 2: Browse Kyoto's smaller design and craft museums, then spend the afternoon in a café around Okazaki.
                    - Day 3: Keep a flexible half day for shopping, a riverside walk, and one final neighborhood dinner.
                    """,
                    createdAt: fixtureDate(hoursAgo: 4, minutesAgo: 40),
                    model: .appleFoundationModel
                ),
                .init(
                    role: .user,
                    content: "Which area is best if vegetarian dinners and easy transit back to the hotel matter most?",
                    createdAt: fixtureDate(hoursAgo: 4, minutesAgo: 15)
                ),
                .init(
                    role: .assistant,
                    content: """
                    Stay near Sanjo or the edge of Gion. You'll have the strongest mix of vegetarian dinners, evening walkability, and simple transit connections without feeling stuck in the busiest tourist blocks.
                    """,
                    createdAt: fixtureDate(hoursAgo: 4),
                    model: .appleFoundationModel
                )
            ]
        )

        let document = ImportedDocument(
            fileName: "Barcelona-Neighborhood-Notes.md",
            extractedText: """
            Trip goal: choose the best Barcelona neighborhood for a first-time visitor who wants great food, walkability, and easy airport access.

            Notes:
            - Eixample feels calm, central, and easy to navigate.
            - El Born is charming and food-forward, but can feel busier at night.
            - Gràcia is relaxed and local, though slightly less convenient for first-time logistics.
            - Prioritize one standout recommendation plus two backup options.
            """,
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let composedPrompt = DocumentPromptComposer.compose(
            userText: "Summarize these notes and recommend the best neighborhood for a first-time Barcelona trip.",
            documents: [document]
        )

        _ = try await seedConversation(
            title: "Barcelona Neighborhood Guide",
            messages: [
                .init(
                    role: .user,
                    content: composedPrompt,
                    createdAt: fixtureDate(hoursAgo: 2, minutesAgo: 35)
                ),
                .init(
                    role: .assistant,
                    content: """
                    Eixample is the strongest first pick. It gives you elegant, walkable blocks, excellent food access, and straightforward transit to both major sights and the airport.

                    Good backups:
                    - El Born for a more atmospheric, food-focused stay
                    - Gràcia for a quieter, more local neighborhood feel
                    """,
                    createdAt: fixtureDate(hoursAgo: 2, minutesAgo: 12),
                    model: .appleFoundationModel
                )
            ]
        )

        let kyotoConversation = try await DataService.shared.fetchConversation(id: kyotoID)

        if let kyotoConversation {
            try await DataService.shared.updateConversationSystemPrompt(
                id: kyotoConversation.id,
                systemPrompt: "You are a thoughtful travel planner. Be concise, practical, and easy to skim on iPhone."
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
