import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

actor FoundationModelsProvider: AIProvider {
    let id = "foundationModels"
    let displayName = "Apple Intelligence"
    let providerType: AIProviderType = .foundationModels

    func checkAvailability() async -> Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    func listModels() async throws -> [AIModel] {
        guard await checkAvailability() else {
            throw AIProviderError.unavailable(
                "Apple Intelligence is not available on this device or requires setup."
            )
        }
        return [.appleFoundationModel]
    }

    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard await self.checkAvailability() else {
                    continuation.finish(
                        throwing: AIProviderError.unavailable(
                            "Apple Intelligence is not available."
                        )
                    )
                    return
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    await self.streamWithFoundationModels(
                        messages: messages,
                        options: options,
                        continuation: continuation
                    )
                } else {
                    continuation.finish(
                        throwing: AIProviderError.unavailable("Requires iOS 26 or macOS 26.")
                    )
                }
            }
        }
    }

    // MARK: - iOS 26 Foundation Models streaming
    //
    // API reference (iOS 26 / WWDC 2025):
    //   LanguageModelSession(instructions:)            – session with optional system instructions
    //   session.streamResponse(to: String) -> ...     – streams LanguageModelStreamedResponse
    //   response.text                                 – the partial accumulated text per fragment
    //   SystemLanguageModel.default.isAvailable       – availability gate

    @available(iOS 26.0, macOS 26.0, *)
    private func streamWithFoundationModels(
        messages: [ChatMessage],
        options: ChatOptions,
        continuation: AsyncThrowingStream<ChatToken, Error>.Continuation
    ) async {
        do {
            let instructions = options.systemPrompt?.isEmpty == false
                ? options.systemPrompt!
                : """
                  You are Lumen, a helpful, private, and knowledgeable AI assistant. \
                  You run entirely on the user's device with no data leaving it. \
                  Be concise, accurate, and friendly.
                  """

            let session = LanguageModelSession(instructions: instructions)

            guard let lastUserMessage = messages.last(where: { $0.isUser }) else {
                continuation.finish(throwing: AIProviderError.invalidResponse("No user message found"))
                return
            }

            var fullText = ""
            let responseStream = session.streamResponse(to: lastUserMessage.content)
            for try await partialResult in responseStream {
                fullText = partialResult.text
                continuation.yield(ChatToken(text: partialResult.text, isComplete: false))
            }
            continuation.yield(ChatToken(text: fullText, isComplete: true, finishReason: .stop))
            continuation.finish()

        } catch is CancellationError {
            continuation.finish(throwing: AIProviderError.cancelled)
        } catch {
            continuation.finish(throwing: AIProviderError.networkError(error))
        }
    }
}
