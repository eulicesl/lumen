import Foundation
@testable import Lumen

actor MockAIProvider: AIProvider {
    let id: String
    let displayName: String
    let providerType: AIProviderType

    var shouldBeAvailable: Bool = true
    var stubbedModels: [AIModel] = [
        AIModel(
            id: "mock.model-a",
            name: "Mock Model A",
            providerType: .ollama,
            supportsStreaming: true
        ),
        AIModel(
            id: "mock.model-b",
            name: "Mock Model B",
            providerType: .ollama,
            supportsImages: true
        )
    ]
    var stubbedResponse: String = "This is a mock response from the AI."
    var shouldThrowError: Bool = false
    var stubbedError: Error = AIProviderError.unavailable("Mock error")
    var chatCallCount: Int = 0
    var lastReceivedMessages: [ChatMessage] = []
    var lastReceivedModel: AIModel?
    var lastReceivedOptions: ChatOptions?

    init(
        id: String = "mock",
        displayName: String = "Mock Provider",
        providerType: AIProviderType = .ollama
    ) {
        self.id = id
        self.displayName = displayName
        self.providerType = providerType
    }

    func checkAvailability() async -> Bool {
        shouldBeAvailable
    }

    func listModels() async throws -> [AIModel] {
        if shouldThrowError { throw stubbedError }
        return stubbedModels
    }

    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error> {
        chatCallCount += 1
        lastReceivedMessages = messages
        lastReceivedModel = model
        lastReceivedOptions = options

        let response = stubbedResponse
        let shouldFail = shouldThrowError
        let error = stubbedError

        return AsyncThrowingStream { continuation in
            Task {
                if shouldFail {
                    continuation.finish(throwing: error)
                    return
                }
                let words = response.components(separatedBy: " ")
                var accumulated = ""
                for (index, word) in words.enumerated() {
                    let isLast = index == words.count - 1
                    accumulated += (index == 0 ? "" : " ") + word
                    continuation.yield(
                        ChatToken(
                            text: accumulated,
                            isComplete: isLast,
                            tokenCount: isLast ? words.count : nil,
                            finishReason: isLast ? .stop : nil
                        )
                    )
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                continuation.finish()
            }
        }
    }
}

actor UnavailableProvider: AIProvider {
    let id = "unavailable"
    let displayName = "Unavailable Provider"
    let providerType: AIProviderType = .ollama

    func checkAvailability() async -> Bool { false }
    func listModels() async throws -> [AIModel] {
        throw AIProviderError.unavailable("This provider is always unavailable")
    }
    func chat(messages: [ChatMessage], model: AIModel, options: ChatOptions) -> AsyncThrowingStream<ChatToken, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: AIProviderError.unavailable("Unavailable"))
        }
    }
}
