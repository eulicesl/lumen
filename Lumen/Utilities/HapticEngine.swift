import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: - HapticEngine

/// Centralised haptic feedback. All methods are no-ops on macOS.
enum HapticEngine {

    // MARK: - Impact

    enum ImpactStyle {
        case light, medium, heavy, soft, rigid
    }

    static func impact(_ style: ImpactStyle = .medium) {
        #if os(iOS)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light:  uiStyle = .light
        case .medium: uiStyle = .medium
        case .heavy:  uiStyle = .heavy
        case .soft:   uiStyle = .soft
        case .rigid:  uiStyle = .rigid
        }
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Notification

    enum NotificationStyle {
        case success, warning, error
    }

    static func notification(_ style: NotificationStyle) {
        #if os(iOS)
        let uiStyle: UINotificationFeedbackGenerator.FeedbackType
        switch style {
        case .success: uiStyle = .success
        case .warning: uiStyle = .warning
        case .error:   uiStyle = .error
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(uiStyle)
        #endif
    }

    // MARK: - Selection

    static func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}
