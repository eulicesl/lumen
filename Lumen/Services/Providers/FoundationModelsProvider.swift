import Foundation

#if canImport(FoundationModels)
import FoundationModels

actor FoundationModelsProvider: AIProvider {
    let id = "foundationModels"
    let displayName = "Apple Intelligence"
    let providerType: AIProviderType = .foundationModels

    func checkAvailability() async -> Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.supportsLocale() else { return false }
            if case .available = model.availability {
                return true
            }
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
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                break
            case .unavailable(let reason):
                continuation.finish(throwing: AIProviderError.unavailable(unavailableReason(reason)))
                return
            }

            guard model.supportsLocale() else {
                continuation.finish(
                    throwing: AIProviderError.unavailable(
                        "Apple Intelligence does not support the current app language or locale."
                    )
                )
                return
            }

            guard messages.contains(where: { $0.isUser }) else {
                continuation.finish(throwing: AIProviderError.invalidResponse("No user message found"))
                return
            }

            let session = LanguageModelSession(instructions: buildInstructions(systemPrompt: options.systemPrompt))
            let prompt = buildPrompt(from: messages)

            var streamedText = ""
            let responseStream = session.streamResponse(
                to: prompt,
                options: generationOptions(from: options)
            )

            for try await snapshot in responseStream {
                let aggregate = snapshot.content
                let delta = String(aggregate.dropFirst(streamedText.count))
                streamedText = aggregate

                if !delta.isEmpty {
                    continuation.yield(ChatToken(text: delta, isComplete: false))
                }
            }

            continuation.yield(
                ChatToken(
                    text: "",
                    isComplete: true,
                    finishReason: .stop
                )
            )
            continuation.finish()

        } catch is CancellationError {
            continuation.finish(throwing: AIProviderError.cancelled)
        } catch let error as LanguageModelSession.GenerationError {
            continuation.finish(throwing: mapGenerationError(error))
        } catch {
            continuation.finish(throwing: AIProviderError.networkError(error))
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func buildInstructions(systemPrompt: String?) -> String {
        let baseInstructions = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? systemPrompt!.trimmingCharacters(in: .whitespacesAndNewlines)
            : """
            You are Lumen, a helpful, private, and knowledgeable AI assistant.
            You run entirely on the user's device with no data leaving it.
            Be concise, accurate, and friendly.
            """

        let localeInstruction = localeInstructionString()
        return [baseInstructions, localeInstruction]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private func buildPrompt(from messages: [ChatMessage]) -> String {
        let transcript = messages
            .filter { $0.isUser || $0.isAssistant }
            .map { message in
                let role = message.isUser ? "User" : "Assistant"
                return "\(role): \(message.content)"
            }
            .joined(separator: "\n\n")

        return """
        Continue this conversation naturally. Reply to the latest user message.

        \(transcript)
        """
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func generationOptions(from options: ChatOptions) -> GenerationOptions {
        var generationOptions = GenerationOptions()
        if let maxTokens = options.maxTokens {
            generationOptions.maximumResponseTokens = maxTokens
        }
        return generationOptions
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func localeInstructionString(for locale: Locale = .current) -> String {
        if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            return ""
        }

        return "The person's locale is \(locale.identifier)."
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func unavailableReason(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Apple Intelligence is not supported on this device."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off in Settings."
        case .modelNotReady:
            return "Apple Intelligence is still downloading or preparing the on-device model."
        default:
            return "Apple Intelligence is currently unavailable."
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> AIProviderError {
        switch error {
        case .exceededContextWindowSize:
            return .contextWindowExceeded
        case .rateLimited:
            return .rateLimited
        case .unsupportedLanguageOrLocale(let context):
            return .unavailable(String(describing: context))
        default:
            return .networkError(error)
        }
    }
}
#else
actor FoundationModelsProvider: AIProvider {
    let id = "foundationModels"
    let displayName = "Apple Intelligence"
    let providerType: AIProviderType = .foundationModels

    func checkAvailability() async -> Bool { false }

    func listModels() async throws -> [AIModel] {
        throw AIProviderError.unavailable(
            "Apple Intelligence requires the Foundation Models framework."
        )
    }

    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: AIProviderError.unavailable(
                    "Apple Intelligence requires iOS 26 or macOS 26."
                )
            )
        }
    }
}
#endif
