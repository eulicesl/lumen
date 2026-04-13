import Foundation

// MARK: - Agent event (streamed to callers)

enum AgentEvent: Sendable {
    case token(String)
    case toolCall(name: String, input: String)
    case toolResult(name: String, result: String)
    case complete(tokenCount: Int?)
    case error(String)
}

// MARK: - AgentService actor

actor AgentService {
    static let shared = AgentService()

    private let maxIterations = 6
    private let toolCallPattern = #/\[\[TOOL:(?<name>[^\|]+)\|(?<input>[^\]]*)\]\]/#

    private init() {}

    // MARK: - Run agent loop

    /// Runs the agent loop and yields AgentEvents.
    /// The caller is responsible for assembling the final message content.
    func run(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncStream<AgentEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: AgentEvent.self)

        Task {
            await self.executeLoop(
                messages: messages,
                model: model,
                options: agentOptions(from: options),
                continuation: continuation
            )
        }

        return stream
    }

    // MARK: - Private loop

    private func executeLoop(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions,
        continuation: AsyncStream<AgentEvent>.Continuation
    ) async {
        var currentMessages = messages
        var iteration = 0
        var totalTokens: Int? = nil

        while iteration < maxIterations {
            iteration += 1
            var assistantContent = ""
            var iterationTokenCount: Int? = nil

            let stream = await AIService.shared.chat(
                messages: currentMessages,
                model: model,
                options: options
            )

            do {
                for try await token in stream {
                    assistantContent += token.text
                    // Yield the full accumulated content; strip markup only when
                    // it might be present to avoid O(n²) regex on every token.
                    let display = assistantContent.mayContainAgentMarkup
                        ? assistantContent.stripAgentMarkup()
                        : assistantContent
                    continuation.yield(.token(display))
                    if token.isComplete {
                        iterationTokenCount = token.tokenCount
                        if let count = token.tokenCount {
                            totalTokens = (totalTokens ?? 0) + count
                        }
                    }
                }
            } catch {
                continuation.yield(.error(error.localizedDescription))
                continuation.finish()
                return
            }

            let toolCalls = extractToolCalls(from: assistantContent)
            guard !toolCalls.isEmpty else {
                continuation.yield(.complete(tokenCount: totalTokens ?? iterationTokenCount))
                continuation.finish()
                return
            }

            var toolResultText = ""
            for (name, input) in toolCalls {
                continuation.yield(.toolCall(name: name, input: input))

                let result: String
                if let tool = AgentToolRegistry.tool(named: name) {
                    result = await tool.run(input: input)
                } else {
                    result = "Error: unknown tool '\(name)'"
                }

                continuation.yield(.toolResult(name: name, result: result))
                toolResultText += "\n[[RESULT:\(result)]]"
            }

            // Keep raw markup in agent loop context so subsequent iterations
            // can see tool results. Display-side stripping happens in the UI layer.
            let assistantMsg = ChatMessage.assistantMessage(
                assistantContent + toolResultText,
                tokenCount: iterationTokenCount
            )
            currentMessages.append(assistantMsg)

            let continueMsg = ChatMessage.userMessage(
                "Please continue based on the tool results above."
            )
            currentMessages.append(continueMsg)
        }

        continuation.yield(.complete(tokenCount: totalTokens))
        continuation.finish()
    }

    // MARK: - Tool call extraction

    private func extractToolCalls(from text: String) -> [(name: String, input: String)] {
        var results: [(name: String, input: String)] = []
        for match in text.matches(of: toolCallPattern) {
            results.append((
                name: String(match.output.name).trimmingCharacters(in: .whitespaces),
                input: String(match.output.input)
            ))
        }
        return results
    }

    // MARK: - Build agent-augmented options

    private func agentOptions(from base: ChatOptions) -> ChatOptions {
        var opts = base
        let toolFragment = AgentToolRegistry.systemPromptFragment
        if let existing = base.systemPrompt, !existing.isEmpty {
            opts.systemPrompt = existing + "\n\n" + toolFragment
        } else {
            opts.systemPrompt = toolFragment
        }
        return opts
    }
}
