import SwiftUI
import Observation

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    var selectedTab: LumenTab = .chat
    var colorScheme: ColorScheme? = nil
    var ollamaBaseURL: String = "http://localhost:11434"
    var ollamaBearerToken: String = ""
    var defaultModelID: String?
    var isFirstLaunch: Bool = false

    var ollamaAvailable: Bool = false
    var foundationModelsAvailable: Bool = false

    var showingOnboarding: Bool = false
    var showingSettings: Bool = false
    var activeAlert: AppAlert? = nil

    private init() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            showingOnboarding = true
        }
        ollamaBaseURL = UserDefaults.standard.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        defaultModelID = UserDefaults.standard.string(forKey: "defaultModelID")
    }

    func saveOllamaURL(_ urlString: String) {
        ollamaBaseURL = urlString
        UserDefaults.standard.set(urlString, forKey: "ollamaBaseURL")
        Task {
            await syncOllamaConfiguration()
        }
    }

    func saveDefaultModel(_ modelID: String) {
        defaultModelID = modelID
        UserDefaults.standard.set(modelID, forKey: "defaultModelID")
    }

    func checkProviderAvailability() async {
        let availability = await AIService.shared.checkAvailability()
        await MainActor.run {
            ollamaAvailable = availability[.ollama] ?? false
            foundationModelsAvailable = availability[.foundationModels] ?? false
        }
    }

    private func syncOllamaConfiguration() async {
        guard let url = URL(string: ollamaBaseURL) else { return }
        let token = ollamaBearerToken.isEmpty ? nil : ollamaBearerToken
        await AIService.shared.configureOllama(baseURL: url, bearerToken: token)
    }
}

enum LumenTab: String, CaseIterable, Identifiable {
    case chat    = "chat"
    case voice   = "voice"
    case library = "library"
    case search  = "search"
    case settings = "settings"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat:     return "Chat"
        case .voice:    return "Voice"
        case .library:  return "Library"
        case .search:   return "Search"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .chat:     return LumenIcon.chat
        case .voice:    return LumenIcon.voice
        case .library:  return LumenIcon.library
        case .search:   return LumenIcon.search
        case .settings: return LumenIcon.settings
        }
    }
}

struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let dismissLabel: String
    let action: (() -> Void)?

    init(title: String, message: String, dismissLabel: String = "OK", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.dismissLabel = dismissLabel
        self.action = action
    }
}
