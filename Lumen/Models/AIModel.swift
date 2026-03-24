import Foundation

struct AIModel: Identifiable, Hashable, Sendable, Codable {
    let id: String
    let name: String
    let displayName: String
    let providerType: AIProviderType
    let supportsImages: Bool
    let supportsStreaming: Bool
    let contextLength: Int?
    let parameterCount: String?
    let description: String?

    init(
        id: String,
        name: String,
        displayName: String? = nil,
        providerType: AIProviderType,
        supportsImages: Bool = false,
        supportsStreaming: Bool = true,
        contextLength: Int? = nil,
        parameterCount: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.providerType = providerType
        self.supportsImages = supportsImages
        self.supportsStreaming = supportsStreaming
        self.contextLength = contextLength
        self.parameterCount = parameterCount
        self.description = description
    }

    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension AIModel {
    static let appleFoundationModel = AIModel(
        id: "foundation-models.apple",
        name: "apple-foundation",
        displayName: "Apple Intelligence",
        providerType: .foundationModels,
        supportsImages: true,
        supportsStreaming: true,
        contextLength: 4096,
        description: "On-device AI using Apple Intelligence. Private, fast, and requires no configuration."
    )

    static let ollamaPlaceholder = AIModel(
        id: "ollama.placeholder",
        name: "llama3.2",
        displayName: "Llama 3.2",
        providerType: .ollama,
        supportsImages: false,
        supportsStreaming: true,
        contextLength: 128_000,
        parameterCount: "3B",
        description: "Meta's Llama 3.2 3B model running locally via Ollama."
    )
}
