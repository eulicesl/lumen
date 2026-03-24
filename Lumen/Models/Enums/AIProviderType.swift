import Foundation

enum AIProviderType: String, Sendable, Codable, CaseIterable, Identifiable {
    case ollama          = "ollama"
    case foundationModels = "foundationModels"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama:           return "Ollama"
        case .foundationModels: return "Apple Intelligence"
        }
    }

    var iconName: String {
        switch self {
        case .ollama:           return LumenIcon.ollama
        case .foundationModels: return LumenIcon.onDevice
        }
    }

    var isOnDevice: Bool {
        self == .foundationModels
    }

    var requiresNetworkSetup: Bool {
        self == .ollama
    }

    var shortName: String {
        switch self {
        case .ollama:           return "Ollama"
        case .foundationModels: return "On-Device"
        }
    }
}
