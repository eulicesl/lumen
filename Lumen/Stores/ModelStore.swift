import Foundation
import Observation

enum ProviderConnectionStatus: Equatable {
    case disabled
    case missingCredentials
    case checking
    case available(modelCount: Int)
    case unavailable(message: String)

    var title: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .missingCredentials:
            return "Needs Credentials"
        case .checking:
            return "Checking"
        case .available(let modelCount):
            return modelCount == 1 ? "1 model available" : "\(modelCount) models available"
        case .unavailable:
            return "Unavailable"
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
    var ollamaLocalConnectionStatus: ProviderConnectionStatus = .checking
    var ollamaCloudConnectionStatus: ProviderConnectionStatus = .disabled

    private let aiService = AIService.shared

    private init() {}

    func loadModels() async {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        ollamaLocalConnectionStatus = AppStore.shared.allowOllamaLocal ? .checking : .disabled
        ollamaCloudConnectionStatus = AppStore.shared.allowOllamaCloud ? .checking : .disabled
        defer { isLoading = false }

        await syncOllamaConfiguration()

        let foundationModels = await aiService.listFoundationModels()
        var ollamaLocalModels: [AIModel] = []
        var ollamaCloudModels: [AIModel] = []

        if AppStore.shared.allowOllamaLocal {
            do {
                ollamaLocalModels = try await aiService.listOllamaLocalModels()
                ollamaLocalConnectionStatus = .available(modelCount: ollamaLocalModels.count)
            } catch {
                let message = Self.providerErrorMessage(
                    for: error,
                    endpointLabel: AppStore.shared.ollamaLocalServerURL,
                    providerName: "Ollama Local",
                    reachabilityHint: "Check that the server is running and reachable on your local network."
                )
                ollamaLocalConnectionStatus = .unavailable(message: message)
                lastError = message
            }
        }

        if AppStore.shared.allowOllamaCloud {
            if AppStore.shared.ollamaCloudAPIKey.isEmpty {
                ollamaCloudConnectionStatus = .missingCredentials
            } else {
                do {
                    ollamaCloudModels = try await aiService.listOllamaCloudModels()
                    ollamaCloudConnectionStatus = .available(modelCount: ollamaCloudModels.count)
                } catch {
                    let message = Self.providerErrorMessage(
                        for: error,
                        endpointLabel: "ollama.com",
                        providerName: "Ollama Cloud",
                        reachabilityHint: "Check your API key and internet connection."
                    )
                    ollamaCloudConnectionStatus = .unavailable(message: message)
                    lastError = message
                }
            }
        }

        availableModels = foundationModels + ollamaLocalModels + ollamaCloudModels

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

    var ollamaLocalModels: [AIModel] {
        availableModels.filter { $0.providerType == .ollamaLocal }
    }

    var ollamaCloudModels: [AIModel] {
        availableModels.filter { $0.providerType == .ollamaCloud }
    }

    var foundationModels: [AIModel] {
        availableModels.filter { $0.providerType == .foundationModels }
    }

    var ollamaModelCount: Int { ollamaLocalModels.count + ollamaCloudModels.count }
    var appleIntelligenceAvailable: Bool { !foundationModels.isEmpty }
    var hasAnyModels: Bool { !availableModels.isEmpty }
    var ollamaLocalStatusMessage: String? { statusMessage(for: .ollamaLocal, status: ollamaLocalConnectionStatus) }
    var ollamaCloudStatusMessage: String? { statusMessage(for: .ollamaCloud, status: ollamaCloudConnectionStatus) }
    
    private func syncOllamaConfiguration() async {
        let urlString = AppStore.shared.ollamaLocalServerURL
        guard let url = URL(string: urlString) else { return }
        let localToken = AppStore.shared.ollamaLocalBearerToken.isEmpty ? nil : AppStore.shared.ollamaLocalBearerToken
        let cloudToken = AppStore.shared.ollamaCloudAPIKey.isEmpty ? nil : AppStore.shared.ollamaCloudAPIKey
        await aiService.configureOllamaLocal(baseURL: url, bearerToken: localToken)
        await aiService.configureOllamaCloud(apiKey: cloudToken)
    }

    nonisolated static func providerErrorMessage(
        for error: Error,
        endpointLabel: String,
        providerName: String,
        reachabilityHint: String
    ) -> String {
        let endpoint = URL(string: endpointLabel)?.host(percentEncoded: false) ?? endpointLabel

        if let providerError = error as? AIProviderError {
            switch providerError {
            case .networkError(let underlying as URLError):
                switch underlying.code {
                case .timedOut:
                    return "Timed out reaching \(providerName) at \(endpoint). \(reachabilityHint)"
                default:
                    return "Can't reach \(providerName) at \(endpoint). \(reachabilityHint)"
                }
            case .invalidResponse(let detail):
                return "\(providerName) responded unexpectedly. \(detail)"
            case .unavailable(let reason):
                return reason
            default:
                return providerError.localizedDescription
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "Timed out reaching \(providerName) at \(endpoint). \(reachabilityHint)"
            default:
                return "Can't reach \(providerName) at \(endpoint). \(reachabilityHint)"
            }
        }

        return error.localizedDescription
    }

    private func statusMessage(
        for providerType: AIProviderType,
        status: ProviderConnectionStatus
    ) -> String? {
        switch (providerType, status) {
        case (_, .disabled):
            return "Enable \(providerType.displayName) to load models."
        case (.foundationModels, .missingCredentials):
            return "Apple Intelligence does not use separate credentials."
        case (.ollamaCloud, .missingCredentials):
            return "Add an Ollama Cloud API key to load hosted models."
        case (.ollamaLocal, .missingCredentials):
            return "Add credentials for your local Ollama endpoint if it requires authentication."
        case (_, .checking):
            return "Checking \(providerType.displayName)."
        case (.ollamaLocal, .available):
            return "Connected to your local Ollama endpoint."
        case (.ollamaCloud, .available):
            return "Connected to Ollama Cloud."
        case (.foundationModels, .available):
            return "Available on this device."
        case (_, .unavailable(let message)):
            return message
        }
    }
}
