import Foundation

actor AIService {
    static let shared = AIService()

    private let ollamaProvider: OllamaProvider
    private let foundationModelsProvider: FoundationModelsProvider

    private init() {
        self.ollamaProvider = OllamaProvider()
        self.foundationModelsProvider = FoundationModelsProvider()
    }

    func provider(for type: AIProviderType) -> any AIProvider {
        switch type {
        case .ollama:           return ollamaProvider
        case .foundationModels: return foundationModelsProvider
        }
    }

    func configureOllama(baseURL: URL, bearerToken: String? = nil) async {
        await ollamaProvider.updateBaseURL(baseURL)
        await ollamaProvider.updateBearerToken(bearerToken)
    }

    func checkAvailability() async -> [AIProviderType: Bool] {
        async let ollamaAvailable = ollamaProvider.checkAvailability()
        async let fmAvailable = foundationModelsProvider.checkAvailability()
        return await [
            .ollama: ollamaAvailable,
            .foundationModels: fmAvailable
        ]
    }

    func listAllModels() async -> [AIModel] {
        var models: [AIModel] = []
        if await foundationModelsProvider.checkAvailability() {
            if let fmModels = try? await foundationModelsProvider.listModels() {
                models.append(contentsOf: fmModels)
            }
        }
        if await ollamaProvider.checkAvailability() {
            if let ollamaModels = try? await ollamaProvider.listModels() {
                models.append(contentsOf: ollamaModels)
            }
        }
        return models
    }

    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error> {
        let selectedProvider = provider(for: model.providerType)
        return AsyncThrowingStream { continuation in
            Task {
                let stream = await selectedProvider.chat(
                    messages: messages,
                    model: model,
                    options: options
                )
                do {
                    for try await token in stream {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func bestAvailableModel() async -> AIModel? {
        if await foundationModelsProvider.checkAvailability() {
            return .appleFoundationModel
        }
        if await ollamaProvider.checkAvailability(),
           let ollamaModels = try? await ollamaProvider.listModels(),
           let first = ollamaModels.first {
            return first
        }
        return nil
    }
}

