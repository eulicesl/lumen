import Foundation

enum AIProviderType: String, Sendable, Codable, CaseIterable, Identifiable {
    case ollamaLocal      = "ollamaLocal"
    case ollamaCloud      = "ollamaCloud"
    case foundationModels = "foundationModels"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollamaLocal:      return "Ollama Local"
        case .ollamaCloud:      return "Ollama Cloud"
        case .foundationModels: return "Apple Intelligence"
        }
    }

    var iconName: String {
        switch self {
        case .ollamaLocal:      return LumenIcon.ollama
        case .ollamaCloud:      return LumenIcon.ollamaCloud
        case .foundationModels: return LumenIcon.onDevice
        }
    }

    var badgeIconName: String? {
        switch self {
        case .ollamaLocal:
            return "server.rack"
        case .ollamaCloud:
            return "cloud.fill"
        case .foundationModels:
            return nil
        }
    }

    var isOnDevice: Bool {
        self == .foundationModels
    }

    var requiresNetworkSetup: Bool {
        self != .foundationModels
    }

    var shortName: String {
        switch self {
        case .ollamaLocal:      return "Local"
        case .ollamaCloud:      return "Cloud"
        case .foundationModels: return "On-Device"
        }
    }

    static func fromStoredValue(_ rawValue: String) -> AIProviderType {
        switch rawValue {
        case "ollama":
            return .ollamaLocal
        default:
            return AIProviderType(rawValue: rawValue) ?? .ollamaLocal
        }
    }
}
