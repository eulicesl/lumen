import Foundation

struct ChatToken: Sendable {
    let text: String
    let isComplete: Bool
    let tokenCount: Int?
    let finishReason: FinishReason?

    init(
        text: String,
        isComplete: Bool = false,
        tokenCount: Int? = nil,
        finishReason: FinishReason? = nil
    ) {
        self.text = text
        self.isComplete = isComplete
        self.tokenCount = tokenCount
        self.finishReason = finishReason
    }

    enum FinishReason: String, Sendable, Codable {
        case stop
        case length
        case cancelled
        case error
    }
}

struct ChatOptions: Sendable {
    var temperature: Float = 0.7
    var systemPrompt: String?
    var maxTokens: Int?
    var stream: Bool = true
    var topP: Float?
    var frequencyPenalty: Float?
    var presencePenalty: Float?

    init(
        temperature: Float = 0.7,
        systemPrompt: String? = nil,
        maxTokens: Int? = nil,
        stream: Bool = true,
        topP: Float? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil
    ) {
        self.temperature = temperature
        self.systemPrompt = systemPrompt
        self.maxTokens = maxTokens
        self.stream = stream
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
    }

    static let defaults = ChatOptions()

    static func withSystemPrompt(_ prompt: String) -> ChatOptions {
        var opts = ChatOptions.defaults
        opts.systemPrompt = prompt
        return opts
    }
}
