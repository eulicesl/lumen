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
    private let dataService = DataService.shared

    private init() {}

    func loadModels() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        availableModels = await aiService.listAllModels()
        if selectedModel == nil {
            selectedModel = availableModels.first
        }
    }

    func selectModel(_ model: AIModel) {
        selectedModel = model
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

    var hasOllamaModels: Bool { !ollamaModels.isEmpty }
    var hasFoundationModels: Bool { !foundationModels.isEmpty }
    var hasAnyModels: Bool { !availableModels.isEmpty }
}
