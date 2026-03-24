import SwiftUI

enum LumenButtonStyle {
    case primary
    case secondary
    case destructive
    case ghost
    case icon
}

struct LumenButton: View {

    let title: String?
    let icon: String?
    let style: LumenButtonStyle
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String? = nil,
        icon: String? = nil,
        style: LumenButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumenSpacing.xxs) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(foregroundColor)
                } else if let icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                }
                if let title {
                    Text(title)
                        .font(LumenType.buttonLabel)
                        .fontWeight(style == .primary ? .semibold : .regular)
                }
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, style == .icon ? LumenSpacing.xs : LumenSpacing.md)
            .padding(.vertical, style == .icon ? LumenSpacing.xs : LumenSpacing.sm)
            .frame(minWidth: style == .icon ? LumenLayout.minTouchTarget : nil,
                   minHeight: LumenLayout.minTouchTarget)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(LumenAnimation.snappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { pressing in isPressed = pressing },
            perform: {}
        )
        .disabled(isLoading)
    }

    private var foregroundColor: Color {
        guard isEnabled else { return LumenColor.disabled }
        switch style {
        case .primary:     return .white
        case .secondary:   return LumenColor.tint
        case .destructive: return .white
        case .ghost:       return LumenColor.tint
        case .icon:        return LumenColor.secondaryText
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LumenColor.tint
        case .secondary:
            LumenColor.tint.opacity(0.12)
        case .destructive:
            LumenColor.destructive
        case .ghost:
            Color.clear
        case .icon:
            Color.clear
        }
    }
}

extension LumenButton {
    static func send(isLoading: Bool = false, action: @escaping () -> Void) -> LumenButton {
        LumenButton(icon: LumenIcon.send, style: .primary, isLoading: isLoading, action: action)
    }

    static func stop(action: @escaping () -> Void) -> LumenButton {
        LumenButton(icon: LumenIcon.stop, style: .secondary, action: action)
    }
}

#Preview {
    VStack(spacing: LumenSpacing.lg) {
        LumenButton("Send Message", icon: LumenIcon.send, style: .primary) {}
        LumenButton("Secondary", icon: LumenIcon.copy, style: .secondary) {}
        LumenButton("Delete", icon: LumenIcon.delete, style: .destructive) {}
        LumenButton("Ghost", style: .ghost) {}
        LumenButton(icon: LumenIcon.microphone, style: .icon) {}
        LumenButton("Loading", style: .primary, isLoading: true) {}
    }
    .padding()
}
