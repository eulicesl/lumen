import SwiftData
import Foundation

@Model
final class AIModelSD {
    var id: UUID = UUID()
    var modelID: String = ""
    var name: String = ""
    var displayName: String = ""
    var provider: String = "ollama"
    var supportsImages: Bool = false
    var supportsStreaming: Bool = true
    var contextLength: Int?
    var parameterCount: String?
    var modelDescription: String?

    init(
        id: UUID = UUID(),
        modelID: String,
        name: String,
        displayName: String,
        provider: String = "ollama",
        supportsImages: Bool = false,
        supportsStreaming: Bool = true,
        contextLength: Int? = nil,
        parameterCount: String? = nil,
        modelDescription: String? = nil
    ) {
        self.id = id
        self.modelID = modelID
        self.name = name
        self.displayName = displayName
        self.provider = provider
        self.supportsImages = supportsImages
        self.supportsStreaming = supportsStreaming
        self.contextLength = contextLength
        self.parameterCount = parameterCount
        self.modelDescription = modelDescription
    }

    func toDomain() -> AIModel {
        AIModel(
            id: modelID,
            name: name,
            displayName: displayName,
            providerType: AIProviderType(rawValue: provider) ?? .ollama,
            supportsImages: supportsImages,
            supportsStreaming: supportsStreaming,
            contextLength: contextLength,
            parameterCount: parameterCount,
            description: modelDescription
        )
    }

    static func from(_ model: AIModel) -> AIModelSD {
        AIModelSD(
            modelID: model.id,
            name: model.name,
            displayName: model.displayName,
            provider: model.providerType.rawValue,
            supportsImages: model.supportsImages,
            supportsStreaming: model.supportsStreaming,
            contextLength: model.contextLength,
            parameterCount: model.parameterCount,
            modelDescription: model.description
        )
    }
}
