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
            .opacity(isEnabled ? 1.0 : 0.45)
        }
        .nativeButtonStyle(for: style)
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

private extension View {
    @ViewBuilder
    func nativeButtonStyle(for style: LumenButtonStyle) -> some View {
        #if compiler(>=6.3)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch style {
            case .primary:
                self.buttonStyle(.glassProminent)
            case .secondary:
                self.buttonStyle(.glass)
            case .destructive:
                self.buttonStyle(.glass(.regular.tint(.red)))
            case .ghost, .icon:
                self.buttonStyle(.plain)
            }
        } else {
            switch style {
            case .primary, .secondary, .destructive:
                self.buttonStyle(.borderless)
            case .ghost, .icon:
                self.buttonStyle(.plain)
            }
        }
        #else
        switch style {
        case .primary, .secondary, .destructive:
            self.buttonStyle(.borderless)
        case .ghost, .icon:
            self.buttonStyle(.plain)
        }
        #endif
    }
}

private struct LumenButtonBackground: ViewModifier {
    let style: LumenButtonStyle

    func body(content: Content) -> some View {
        #if compiler(>=6.3)
        if #available(iOS 26.0, macOS 26.0, *) {
            modernBackground(content: content)
        } else {
            legacyBackground(content: content)
        }
        #else
        legacyBackground(content: content)
        #endif
    }

    #if compiler(>=6.3)
    @available(iOS 26.0, macOS 26.0, *)
    @ViewBuilder
    private func modernBackground(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .glassEffect(.regular.tint(.accentColor), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
        case .secondary:
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
        case .destructive:
            content
                .glassEffect(.regular.tint(.red), in: RoundedRectangle(cornerRadius: LumenRadius.md, style: .continuous))
        case .ghost, .icon:
            content
        }
    }
    #endif

    @ViewBuilder
    private func legacyBackground(content: Content) -> some View {
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
