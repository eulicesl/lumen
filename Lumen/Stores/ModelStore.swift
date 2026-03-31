import Foundation
import Observation

enum OllamaConnectionStatus: Equatable {
    case disabled
    case checking
    case available(modelCount: Int)
    case unavailable(message: String)

    var title: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .checking:
            return "Checking"
        case .available(let modelCount):
            return modelCount == 1 ? "1 model available" : "\(modelCount) models available"
        case .unavailable:
            return "Unavailable"
        }
    }

    var detail: String? {
        switch self {
        case .disabled:
            return "Enable Ollama to load models from your local server."
        case .checking:
            return "Checking your configured Ollama server."
        case .available:
            return "Connected to your local Ollama server."
        case .unavailable(let message):
            return message
        }
    }

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}

@Observable
@MainActor
final class ModelStore {
    static let shared = ModelStore()

    var availableModels: [AIModel] = []
    var selectedModel: AIModel?
    var isLoading: Bool = false
    var lastError: String?
    var ollamaConnectionStatus: OllamaConnectionStatus = .checking

    private let aiService = AIService.shared

    private init() {}

    func loadModels() async {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        ollamaConnectionStatus = AppStore.shared.allowOllama ? .checking : .disabled
        defer { isLoading = false }

        await syncOllamaURL()

        let foundationModels = await aiService.listFoundationModels()
        var ollamaModels: [AIModel] = []

        if AppStore.shared.allowOllama {
            do {
                ollamaModels = try await aiService.listOllamaModels()
                ollamaConnectionStatus = .available(modelCount: ollamaModels.count)
            } catch {
                let message = Self.ollamaErrorMessage(
                    for: error,
                    urlString: AppStore.shared.ollamaServerURL
                )
                ollamaConnectionStatus = .unavailable(message: message)
                lastError = message
            }
        }

        availableModels = foundationModels + ollamaModels

        if let savedID = AppStore.shared.defaultModelID,
           let saved = availableModels.first(where: { $0.id == savedID }) {
            selectedModel = saved
        } else if selectedModel == nil || !availableModels.contains(where: { $0.id == selectedModel?.id }) {
            selectedModel = availableModels.first
        }

        if let model = selectedModel {
            ChatStore.shared.currentModel = model
        }
    }

    func selectModel(_ model: AIModel) {
        selectedModel = model
        ChatStore.shared.currentModel = model
        AppStore.shared.saveDefaultModel(model.id)
    }

    func refreshModels() async {
        await loadModels()
    }

    var ollamaModels: [AIModel] {
        availableModels.filter { $0.providerType == .ollama }
    }

    var foundationModels: [AIModel] {
        availableModels.filter { $0.providerType == .foundationModels }
    }

    var ollamaModelCount: Int { ollamaModels.count }
    var appleIntelligenceAvailable: Bool { !foundationModels.isEmpty }
    var hasAnyModels: Bool { !availableModels.isEmpty }
    var ollamaStatusMessage: String? { ollamaConnectionStatus.detail }
    
    private func syncOllamaURL() async {
        let urlString = AppStore.shared.ollamaServerURL
        guard let url = URL(string: urlString) else { return }
        let token = AppStore.shared.ollamaBearerToken.isEmpty ? nil : AppStore.shared.ollamaBearerToken
        await aiService.configureOllama(baseURL: url, bearerToken: token)
    }

    nonisolated static func ollamaErrorMessage(for error: Error, urlString: String) -> String {
        let endpoint = URL(string: urlString)?.host(percentEncoded: false) ?? urlString

        if let providerError = error as? AIProviderError {
            switch providerError {
            case .networkError(let underlying as URLError):
                switch underlying.code {
                case .timedOut:
                    return "Timed out reaching Ollama at \(endpoint). Check that the server is running and reachable on your local network."
                default:
                    return "Can't reach Ollama at \(endpoint). Check that the server is running and the URL is correct."
                }
            case .invalidResponse(let detail):
                return "Ollama responded unexpectedly. \(detail)"
            case .unavailable(let reason):
                return reason
            default:
                return providerError.localizedDescription
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "Timed out reaching Ollama at \(endpoint). Check that the server is running and reachable on your local network."
            default:
                return "Can't reach Ollama at \(endpoint). Check that the server is running and the URL is correct."
            }
        }

        return error.localizedDescription
    }
}
