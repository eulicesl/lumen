import Foundation

protocol AIProvider: Actor {
    var id: String { get }
    var displayName: String { get }
    var providerType: AIProviderType { get }

    func checkAvailability() async -> Bool
    func listModels() async throws -> [AIModel]
    func chat(
        messages: [ChatMessage],
        model: AIModel,
        options: ChatOptions
    ) -> AsyncThrowingStream<ChatToken, Error>
}

enum AIProviderError: Error, LocalizedError {
    case unavailable(String)
    case modelNotFound(String)
    case networkError(Error)
    case invalidResponse(String)
    case cancelled
    case rateLimited
    case contextWindowExceeded

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return "Provider unavailable: \(reason)"
        case .modelNotFound(let name):
            return "Model not found: \(name)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let detail):
            return "Invalid response: \(detail)"
        case .cancelled:
            return "Request cancelled."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .contextWindowExceeded:
            return "The conversation is too long for this model's context window."
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .cancelled, .rateLimited: return true
        default: return false
        }
    }
}
