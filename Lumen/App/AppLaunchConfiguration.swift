import Foundation

enum AppLaunchConfiguration {
    private static let environment = ProcessInfo.processInfo.environment

    static var isReleaseCaptureMode: Bool {
        environment["LUMEN_CAPTURE_MODE"] == "1"
    }

    static var shouldSkipOnboarding: Bool {
        isReleaseCaptureMode
    }

    static var screenshotScene: ReleaseScreenshotScene? {
        guard let rawValue = environment["LUMEN_SCREENSHOT_SCENE"] else { return nil }
        return ReleaseScreenshotScene(rawValue: rawValue)
    }
}

enum ReleaseScreenshotScene: String {
    case chat
    case documents
    case search
    case settings

    var targetConversationTitle: String? {
        switch self {
        case .chat:
            return "Weekend in Portland"
        case .documents:
            return "Launch Brief Review"
        case .search:
            return "Release Checklist"
        case .settings:
            return "Weekend in Portland"
        }
    }

    var opensSearchPanel: Bool {
        self == .search
    }

    var opensSettings: Bool {
        self == .settings
    }

    var searchQuery: String {
        switch self {
        case .search:
            return "privacy"
        case .chat, .documents, .settings:
            return ""
        }
    }
}
