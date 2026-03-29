import SwiftUI
import Observation

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    var selectedTab: LumenTab = .chat
    var colorSchemePreference: AppColorScheme = .system
    var ollamaServerURL: String = "http://localhost:11434"
    var ollamaBearerToken: String = ""
    var allowOllama: Bool = true
    var defaultModelID: String?
    var isFirstLaunch: Bool = false

    var showingSettings: Bool = false
    var activeAlert: AppAlert? = nil

    private init() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        ollamaServerURL = UserDefaults.standard.string(forKey: "ollamaServerURL") ?? "http://localhost:11434"
        ollamaBearerToken = UserDefaults.standard.string(forKey: "ollamaBearerToken") ?? ""
        defaultModelID = UserDefaults.standard.string(forKey: "defaultModelID")
        if UserDefaults.standard.object(forKey: "allowOllama") != nil {
            allowOllama = UserDefaults.standard.bool(forKey: "allowOllama")
        } else {
            allowOllama = true
        }
        if let raw = UserDefaults.standard.string(forKey: "colorSchemePreference"),
           let scheme = AppColorScheme(rawValue: raw) {
            colorSchemePreference = scheme
        }
    }

    var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    func saveOllamaURL(_ urlString: String) {
        ollamaServerURL = urlString
        UserDefaults.standard.set(urlString, forKey: "ollamaServerURL")
        Task { await syncOllamaConfiguration() }
    }

    func saveOllamaBearerToken(_ token: String) {
        ollamaBearerToken = token
        UserDefaults.standard.set(token, forKey: "ollamaBearerToken")
        Task { await syncOllamaConfiguration() }
    }
    
    func saveAllowOllama(_ allow: Bool) {
        allowOllama = allow
        UserDefaults.standard.set(allow, forKey: "allowOllama")
    }

    func saveDefaultModel(_ modelID: String) {
        defaultModelID = modelID
        UserDefaults.standard.set(modelID, forKey: "defaultModelID")
    }

    func saveColorScheme(_ scheme: AppColorScheme) {
        colorSchemePreference = scheme
        UserDefaults.standard.set(scheme.rawValue, forKey: "colorSchemePreference")
    }

    private func syncOllamaConfiguration() async {
        guard let url = URL(string: ollamaServerURL) else { return }
        let token = ollamaBearerToken.isEmpty ? nil : ollamaBearerToken
        await AIService.shared.configureOllama(baseURL: url, bearerToken: token)
    }
}

// MARK: - Enums

enum AppColorScheme: String, CaseIterable {
    case system, light, dark
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
