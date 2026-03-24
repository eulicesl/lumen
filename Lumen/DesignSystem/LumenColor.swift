import SwiftUI

enum LumenColor {

    // MARK: - Text
    static let primaryText     = Color(.label)
    static let secondaryText   = Color(.secondaryLabel)
    static let tertiaryText    = Color(.tertiaryLabel)
    static let placeholderText = Color(.placeholderText)

    // MARK: - Backgrounds
    static let primaryBackground   = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground   = Color(.systemGroupedBackground)
    static let groupedSecondary    = Color(.secondarySystemGroupedBackground)
    static let groupedTertiary     = Color(.tertiarySystemGroupedBackground)

    // MARK: - Chat Bubbles
    static let userBubble      = Color.accentColor.opacity(0.15)
    static let assistantBubble = Color(.secondarySystemGroupedBackground)
    static let systemBubble    = Color(.tertiarySystemGroupedBackground)

    // MARK: - Code Blocks
    static let codeBackground = Color(.systemGray6)

    // MARK: - Status
    static let success = Color.green
    static let warning = Color.orange
    static let error   = Color.red
    static let info    = Color.blue

    // MARK: - Interactive
    static let tint        = Color.accentColor
    static let destructive = Color.red
    static let disabled    = Color(.quaternaryLabel)
    static let separator   = Color(.separator)
}
