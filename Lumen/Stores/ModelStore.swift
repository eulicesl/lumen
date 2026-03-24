import Foundation
import Observation

@Observable
@MainActor
final class ModelStore {
    static let shared = ModelStore()

    var availableModels: [AIModel] = []
    var selectedModel: AIModel?
    var isLoading: Bool = false
    var lastError: String?

    private let aiService = AIService.shared

    private init() {}

    func loadModels() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        await syncOllamaURL()
        availableModels = await aiService.listAllModels()

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

    private func syncOllamaURL() async {
        let urlString = AppStore.shared.ollamaServerURL
        guard let url = URL(string: urlString) else { return }
        await aiService.configureOllama(baseURL: url, bearerToken: nil)
    }
}
