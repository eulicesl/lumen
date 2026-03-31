import SwiftUI
import Observation
import Security

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    private static let hasLaunchedBeforeKey = "hasLaunchedBefore"
    private static let ollamaServerURLKey = "ollamaServerURL"
    private static let ollamaBearerTokenKey = "ollamaBearerToken"
    private static let defaultModelIDKey = "defaultModelID"
    private static let allowOllamaKey = "allowOllama"
    private static let colorSchemePreferenceKey = "colorSchemePreference"

    var selectedTab: LumenTab = .chat
    var colorSchemePreference: AppColorScheme = .system
    var ollamaServerURL: String = "http://localhost:11434"
    var ollamaBearerToken: String = ""
    var allowOllama: Bool = true
    var defaultModelID: String?
    var isFirstLaunch: Bool = false

    var showingSettings: Bool = false
    var activeAlert: AppAlert? = nil

    private let userDefaults: UserDefaults
    private let secretStore: any SecretStore

    init(
        userDefaults: UserDefaults = .standard,
        secretStore: any SecretStore = KeychainSecretStore()
    ) {
        self.userDefaults = userDefaults
        self.secretStore = secretStore

        isFirstLaunch = !userDefaults.bool(forKey: Self.hasLaunchedBeforeKey)
        if isFirstLaunch {
            userDefaults.set(true, forKey: Self.hasLaunchedBeforeKey)
        }
        ollamaServerURL = userDefaults.string(forKey: Self.ollamaServerURLKey) ?? "http://localhost:11434"
        ollamaBearerToken = loadOllamaBearerToken()
        defaultModelID = userDefaults.string(forKey: Self.defaultModelIDKey)
        if userDefaults.object(forKey: Self.allowOllamaKey) != nil {
            allowOllama = userDefaults.bool(forKey: Self.allowOllamaKey)
        } else {
            allowOllama = true
        }
        if let raw = userDefaults.string(forKey: Self.colorSchemePreferenceKey),
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
        userDefaults.set(urlString, forKey: Self.ollamaServerURLKey)
        Task { await syncOllamaConfiguration() }
    }

    func saveOllamaBearerToken(_ token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        ollamaBearerToken = normalizedToken

        do {
            if normalizedToken.isEmpty {
                try secretStore.removeValue(forKey: Self.ollamaBearerTokenKey)
            } else {
                try secretStore.setString(normalizedToken, forKey: Self.ollamaBearerTokenKey)
            }
            userDefaults.removeObject(forKey: Self.ollamaBearerTokenKey)
        } catch {
            activeAlert = AppAlert(
                title: "Secure Storage Failed",
                message: error.localizedDescription
            )
        }

        Task { await syncOllamaConfiguration() }
    }
    
    func saveAllowOllama(_ allow: Bool) {
        allowOllama = allow
        userDefaults.set(allow, forKey: Self.allowOllamaKey)
    }

    func saveDefaultModel(_ modelID: String) {
        defaultModelID = modelID
        userDefaults.set(modelID, forKey: Self.defaultModelIDKey)
    }

    func saveColorScheme(_ scheme: AppColorScheme) {
        colorSchemePreference = scheme
        userDefaults.set(scheme.rawValue, forKey: Self.colorSchemePreferenceKey)
    }

    private func syncOllamaConfiguration() async {
        guard let url = URL(string: ollamaServerURL) else { return }
        let token = ollamaBearerToken.isEmpty ? nil : ollamaBearerToken
        await AIService.shared.configureOllama(baseURL: url, bearerToken: token)
    }

    private func loadOllamaBearerToken() -> String {
        if let storedToken = try? secretStore.string(forKey: Self.ollamaBearerTokenKey),
           !storedToken.isEmpty {
            userDefaults.removeObject(forKey: Self.ollamaBearerTokenKey)
            return storedToken
        }

        let legacyToken = userDefaults.string(forKey: Self.ollamaBearerTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !legacyToken.isEmpty else { return "" }

        do {
            try secretStore.setString(legacyToken, forKey: Self.ollamaBearerTokenKey)
            userDefaults.removeObject(forKey: Self.ollamaBearerTokenKey)
        } catch {
            activeAlert = AppAlert(
                title: "Secure Storage Failed",
                message: error.localizedDescription
            )
        }

        return legacyToken
    }
}

protocol SecretStore {
    func string(forKey key: String) throws -> String?
    func setString(_ value: String, forKey key: String) throws
    func removeValue(forKey key: String) throws
}

struct KeychainSecretStore: SecretStore {
    private let service: String

    init(service: String = (Bundle.main.bundleIdentifier ?? "com.eulices.lumen") + ".secrets") {
        self.service = service
    }

    func string(forKey key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainSecretStoreError(status: status)
        }
    }

    func setString(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw KeychainSecretStoreError(status: updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData] = data

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainSecretStoreError(status: addStatus)
        }
    }

    func removeValue(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainSecretStoreError(status: status)
        }
    }
}

struct KeychainSecretStoreError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error (\(status))"
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
