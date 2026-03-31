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
            .modifier(LumenButtonBackground(style: style))
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(
                LumenMotion.animation(LumenAnimation.snappy, reduceMotion: reduceMotion),
                value: isPressed
            )
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

}

private struct LumenButtonBackground: ViewModifier {
    let style: LumenButtonStyle

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            switch style {
            case .primary:
                content
                    .glassEffect(.regular.tint(.accentColor).interactive(), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .secondary:
                content
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .destructive:
                content
                    .glassEffect(.regular.tint(.red).interactive(), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .ghost, .icon:
                content
            }
        } else {
            switch style {
            case .primary:
                content
                    .background(LumenColor.tint, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .secondary:
                content
                    .background(LumenColor.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .destructive:
                content
                    .background(LumenColor.destructive, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
            case .ghost, .icon:
                content
            }
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
