import Foundation

actor FoundationModelsProvider: AIProvider {
    let id = "foundationModels"
    let displayName = "Apple Intelligence"
    let providerType: AIProviderType = .foundationModels

    func checkAvailability() async -> Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return LanguageModelSession.isAvailable
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

    @available(iOS 26.0, macOS 26.0, *)
    private func streamWithFoundationModels(
        messages: [ChatMessage],
        options: ChatOptions,
        continuation: AsyncThrowingStream<ChatToken, Error>.Continuation
    ) async {
        do {
            var sessionInstructions = ""
            if let systemPrompt = options.systemPrompt, !systemPrompt.isEmpty {
                sessionInstructions = systemPrompt
            } else {
                sessionInstructions = """
                You are Lumen, a helpful, private, and knowledgeable AI assistant. \
                You run entirely on the user's device with no data leaving it. \
                Be concise, accurate, and friendly.
                """
            }

            let session = LanguageModelSession(instructions: sessionInstructions)

            let userMessages = messages.filter { $0.isUser || $0.isAssistant }
            guard let lastUserMessage = userMessages.last(where: { $0.isUser }) else {
                continuation.finish(throwing: AIProviderError.invalidResponse("No user message found"))
                return
            }

            let response = session.streamResponse(to: lastUserMessage.content)
            var fullText = ""
            for try await partial in response {
                fullText = partial
                continuation.yield(ChatToken(text: partial, isComplete: false))
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

#if !os(watchOS)
@available(iOS 26.0, macOS 26.0, *)
private extension LanguageModelSession {
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
}

@available(iOS 26.0, macOS 26.0, *)
private extension LanguageModelSession {
    convenience init(instructions: String) {
        self.init(
            model: .default,
            instructions: instructions
        )
    }

    func streamResponse(to prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = self.streamResponse(to: Prompt(prompt))
                    var accumulated = ""
                    for try await fragment in stream {
                        accumulated += fragment.text
                        continuation.yield(accumulated)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
#endif
