import Foundation

actor AIService {
    static let shared = AIService()

    private let ollamaLocalProvider: OllamaProvider
    private let ollamaCloudProvider: OllamaProvider
    private let foundationModelsProvider: FoundationModelsProvider

    private init() {
        self.ollamaLocalProvider = OllamaProvider(
            id: "ollama-local",
            displayName: "Ollama Local",
            providerType: .ollamaLocal,
            baseURL: URL(string: "http://localhost:11434")!
        )
        self.ollamaCloudProvider = OllamaProvider(
            id: "ollama-cloud",
            displayName: "Ollama Cloud",
            providerType: .ollamaCloud,
            baseURL: URL(string: "https://ollama.com")!
        )
        self.foundationModelsProvider = FoundationModelsProvider()
    }

    func provider(for type: AIProviderType) -> any AIProvider {
        switch type {
        case .ollamaLocal:      return ollamaLocalProvider
        case .ollamaCloud:      return ollamaCloudProvider
        case .foundationModels: return foundationModelsProvider
        }
    }

    func configureOllamaLocal(baseURL: URL, bearerToken: String? = nil) async {
        await ollamaLocalProvider.updateBaseURL(baseURL)
        await ollamaLocalProvider.updateBearerToken(bearerToken)
    }

    func configureOllamaCloud(apiKey: String?) async {
        await ollamaCloudProvider.updateBaseURL(URL(string: "https://ollama.com")!)
        await ollamaCloudProvider.updateBearerToken(apiKey)
    }

    func checkAvailability() async -> [AIProviderType: Bool] {
        async let ollamaLocalAvailable = ollamaLocalProvider.checkAvailability()
        async let ollamaCloudAvailable = ollamaCloudProvider.checkAvailability()
        async let fmAvailable = foundationModelsProvider.checkAvailability()
        return await [
            .ollamaLocal: ollamaLocalAvailable,
            .ollamaCloud: ollamaCloudAvailable,
            .foundationModels: fmAvailable
        ]
    }

    func listAllModels() async -> [AIModel] {
        let foundationModels = await listFoundationModels()
        let ollamaLocalModels = (try? await listOllamaLocalModels()) ?? []
        let ollamaCloudModels = (try? await listOllamaCloudModels()) ?? []
        return foundationModels + ollamaLocalModels + ollamaCloudModels
    }

    func listFoundationModels() async -> [AIModel] {
        guard await foundationModelsProvider.checkAvailability() else { return [] }
        return (try? await foundationModelsProvider.listModels()) ?? []
    }

    func listOllamaLocalModels() async throws -> [AIModel] {
        try await ollamaLocalProvider.listModels()
    }

    func listOllamaCloudModels() async throws -> [AIModel] {
        try await ollamaCloudProvider.listModels()
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
        if await ollamaLocalProvider.checkAvailability(),
           let ollamaModels = try? await ollamaLocalProvider.listModels(),
           let first = ollamaModels.first {
            return first
        }
        if await ollamaCloudProvider.checkAvailability(),
           let ollamaModels = try? await ollamaCloudProvider.listModels(),
           let first = ollamaModels.first {
            return first
        }
        return nil
    }
}
