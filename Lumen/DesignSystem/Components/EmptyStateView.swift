import SwiftUI

// MARK: - EmptyStateView

/// Reusable empty state with SF Symbol, title, subtitle and optional action button.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String
    var symbolColor: Color = .secondary
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: LumenSpacing.lg) {
            Spacer()

            VStack(spacing: LumenSpacing.md) {
                ZStack {
                    Circle()
                        .fill(symbolColor.opacity(0.10))
                        .frame(width: 96, height: 96)

                    Image(systemName: symbol)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(symbolColor.opacity(0.7))
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }

                VStack(spacing: LumenSpacing.sm) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(LumenType.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, LumenSpacing.xl)
                }

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Convenience initialisers

extension EmptyStateView {
    static func noConversations(onNew: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            symbol: "bubble.left.and.bubble.right",
            title: "No Conversations",
            subtitle: "Start a new conversation to chat with your AI assistant.",
            symbolColor: .accentColor,
            actionTitle: "New Conversation",
            action: onNew
        )
    }

    static func noModelSelected() -> EmptyStateView {
        EmptyStateView(
            symbol: "cpu",
            title: "No Model Selected",
            subtitle: "Tap the model button in the toolbar to pick an AI model before chatting.",
            symbolColor: .orange
        )
    }

    static func selectConversation() -> EmptyStateView {
        EmptyStateView(
            symbol: "sidebar.left",
            title: "Select a Conversation",
            subtitle: "Choose a conversation from the sidebar, or start a new one.",
            symbolColor: .accentColor
        )
    }

    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            symbol: "magnifyingglass",
            title: "No Results",
            subtitle: "No conversations matched "\(query)".",
            symbolColor: .secondary
        )
    }
}

#Preview {
    VStack {
        EmptyStateView.noConversations { }
        Divider()
        EmptyStateView.noModelSelected()
    }
}
