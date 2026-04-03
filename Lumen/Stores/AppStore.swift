import SwiftUI
import Observation
import Security

private let keychainServiceName = "com.eulices.lumen.secrets"

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    private static let hasLaunchedBeforeKey = "hasLaunchedBefore"
    private static let ollamaLocalServerURLKey = "ollamaLocalServerURL"
    private static let ollamaLocalBearerTokenKey = "ollamaLocalBearerToken"
    private static let ollamaCloudAPIKeyKey = "ollamaCloudAPIKey"
    private static let defaultModelIDKey = "defaultModelID"
    private static let allowOllamaLocalKey = "allowOllamaLocal"
    private static let allowOllamaCloudKey = "allowOllamaCloud"
    private static let colorSchemePreferenceKey = "colorSchemePreference"
    private static let legacyOllamaServerURLKey = "ollamaServerURL"
    private static let legacyOllamaBearerTokenKey = "ollamaBearerToken"
    private static let legacyAllowOllamaKey = "allowOllama"

    var selectedTab: LumenTab = .chat
    var colorSchemePreference: AppColorScheme = .system
    var ollamaLocalServerURL: String = "http://localhost:11434"
    var ollamaLocalBearerToken: String = ""
    var ollamaCloudAPIKey: String = ""
    var allowOllamaLocal: Bool = true
    var allowOllamaCloud: Bool = false
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
        ollamaLocalServerURL =
            userDefaults.string(forKey: Self.ollamaLocalServerURLKey)
            ?? userDefaults.string(forKey: Self.legacyOllamaServerURLKey)
            ?? "http://localhost:11434"
        ollamaLocalBearerToken = loadSecret(
            currentKey: Self.ollamaLocalBearerTokenKey,
            legacyKey: Self.legacyOllamaBearerTokenKey
        )
        ollamaCloudAPIKey = loadSecret(currentKey: Self.ollamaCloudAPIKeyKey)
        if let storedDefaultModelID = userDefaults.string(forKey: Self.defaultModelIDKey) {
            let normalizedDefaultModelID = Self.normalizeStoredModelID(storedDefaultModelID)
            defaultModelID = normalizedDefaultModelID
            if normalizedDefaultModelID != storedDefaultModelID {
                userDefaults.set(normalizedDefaultModelID, forKey: Self.defaultModelIDKey)
            }
        }
        if userDefaults.object(forKey: Self.allowOllamaLocalKey) != nil {
            allowOllamaLocal = userDefaults.bool(forKey: Self.allowOllamaLocalKey)
        } else {
            allowOllamaLocal = userDefaults.object(forKey: Self.legacyAllowOllamaKey) != nil
                ? userDefaults.bool(forKey: Self.legacyAllowOllamaKey)
                : true
        }
        if userDefaults.object(forKey: Self.allowOllamaCloudKey) != nil {
            allowOllamaCloud = userDefaults.bool(forKey: Self.allowOllamaCloudKey)
        } else {
            allowOllamaCloud = false
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

    func saveOllamaLocalURL(_ urlString: String) {
        ollamaLocalServerURL = urlString
        userDefaults.set(urlString, forKey: Self.ollamaLocalServerURLKey)
        Task { await syncOllamaLocalConfiguration() }
    }

    func saveOllamaLocalBearerToken(_ token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        ollamaLocalBearerToken = normalizedToken

        do {
            if normalizedToken.isEmpty {
                try secretStore.removeValue(forKey: Self.ollamaLocalBearerTokenKey)
            } else {
                try secretStore.setString(normalizedToken, forKey: Self.ollamaLocalBearerTokenKey)
            }
            clearLegacyOllamaLocalBearerTokenIfNeeded()
        } catch {
            activeAlert = AppAlert(
                title: "Secure Storage Failed",
                message: error.localizedDescription
            )
        }

        Task { await syncOllamaLocalConfiguration() }
    }

    func saveOllamaCloudAPIKey(_ token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        ollamaCloudAPIKey = normalizedToken

        do {
            if normalizedToken.isEmpty {
                try secretStore.removeValue(forKey: Self.ollamaCloudAPIKeyKey)
            } else {
                try secretStore.setString(normalizedToken, forKey: Self.ollamaCloudAPIKeyKey)
            }
        } catch {
            activeAlert = AppAlert(
                title: "Secure Storage Failed",
                message: error.localizedDescription
            )
        }

        Task { await syncOllamaCloudConfiguration() }
    }
    
    func saveAllowOllamaLocal(_ allow: Bool) {
        allowOllamaLocal = allow
        userDefaults.set(allow, forKey: Self.allowOllamaLocalKey)
    }

    func saveAllowOllamaCloud(_ allow: Bool) {
        allowOllamaCloud = allow
        userDefaults.set(allow, forKey: Self.allowOllamaCloudKey)
    }

    func saveDefaultModel(_ modelID: String) {
        let normalizedModelID = Self.normalizeStoredModelID(modelID)
        defaultModelID = normalizedModelID
        userDefaults.set(normalizedModelID, forKey: Self.defaultModelIDKey)
    }

    func saveColorScheme(_ scheme: AppColorScheme) {
        colorSchemePreference = scheme
        userDefaults.set(scheme.rawValue, forKey: Self.colorSchemePreferenceKey)
    }

    private func syncOllamaLocalConfiguration() async {
        guard let url = URL(string: ollamaLocalServerURL) else { return }
        let token = ollamaLocalBearerToken.isEmpty ? nil : ollamaLocalBearerToken
        await AIService.shared.configureOllamaLocal(baseURL: url, bearerToken: token)
    }

    private func syncOllamaCloudConfiguration() async {
        let token = ollamaCloudAPIKey.isEmpty ? nil : ollamaCloudAPIKey
        await AIService.shared.configureOllamaCloud(apiKey: token)
    }

    private func loadSecret(currentKey: String, legacyKey: String? = nil) -> String {
        if let storedToken = try? secretStore.string(forKey: currentKey),
           !storedToken.isEmpty {
            if let legacyKey {
                clearLegacySecretIfNeeded(legacyKey: legacyKey)
            }
            return storedToken
        }

        guard let legacyKey else { return "" }

        if let legacyStoredToken = try? secretStore.string(forKey: legacyKey),
           !legacyStoredToken.isEmpty {
            do {
                try secretStore.setString(legacyStoredToken, forKey: currentKey)
                try? secretStore.removeValue(forKey: legacyKey)
                clearLegacySecretIfNeeded(legacyKey: legacyKey)
            } catch {
                activeAlert = AppAlert(
                    title: "Secure Storage Failed",
                    message: error.localizedDescription
                )
            }
            return legacyStoredToken
        }

        let legacyToken = userDefaults.string(forKey: legacyKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !legacyToken.isEmpty else { return "" }

        do {
            try secretStore.setString(legacyToken, forKey: currentKey)
            try? secretStore.removeValue(forKey: legacyKey)
            clearLegacySecretIfNeeded(legacyKey: legacyKey)
        } catch {
            activeAlert = AppAlert(
                title: "Secure Storage Failed",
                message: error.localizedDescription
            )
        }

        return legacyToken
    }

    private func clearLegacyOllamaLocalBearerTokenIfNeeded() {
        clearLegacySecretIfNeeded(legacyKey: Self.legacyOllamaBearerTokenKey)
    }

    private func clearLegacySecretIfNeeded(legacyKey: String) {
        guard userDefaults.object(forKey: legacyKey) != nil else { return }
        userDefaults.removeObject(forKey: legacyKey)
    }

    private static func normalizeStoredModelID(_ modelID: String) -> String {
        let legacyPrefix = "\(AIProviderType.ollamaLocal.rawValue)."
        guard modelID.hasPrefix(legacyPrefix) else { return modelID }
        let suffix = modelID.dropFirst(legacyPrefix.count)
        return "\(AIProviderType.ollamaLocal.stableModelIDPrefix).\(suffix)"
    }

    // MARK: - Legacy compatibility

    var ollamaServerURL: String {
        get { ollamaLocalServerURL }
        set { saveOllamaLocalURL(newValue) }
    }

    var ollamaBearerToken: String {
        get { ollamaLocalBearerToken }
        set { saveOllamaLocalBearerToken(newValue) }
    }

    var allowOllama: Bool {
        get { allowOllamaLocal }
        set { saveAllowOllamaLocal(newValue) }
    }

    func saveOllamaURL(_ urlString: String) {
        saveOllamaLocalURL(urlString)
    }

    func saveOllamaBearerToken(_ token: String) {
        saveOllamaLocalBearerToken(token)
    }

    func saveAllowOllama(_ allow: Bool) {
        saveAllowOllamaLocal(allow)
    }
}

protocol SecretStore {
    func string(forKey key: String) throws -> String?
    func setString(_ value: String, forKey key: String) throws
    func removeValue(forKey key: String) throws
}

struct KeychainSecretStore: SecretStore {
    private let service: String

    init(service: String = keychainServiceName) {
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
