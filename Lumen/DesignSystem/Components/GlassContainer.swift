import SwiftUI

struct GlassContainer<Content: View>: View {

    enum Style {
        case regular
        case interactive
        case prominent
    }

    enum Shape {
        case rectangle
        case capsule
        case roundedRectangle(radius: CGFloat)
    }

    private let style: Style
    private let shape: Shape
    private let padding: EdgeInsets
    private let content: Content

    init(
        style: Style = .regular,
        shape: Shape = .roundedRectangle(radius: LumenRadius.md),
        padding: EdgeInsets = .init(
            top: LumenSpacing.sm,
            leading: LumenSpacing.md,
            bottom: LumenSpacing.sm,
            trailing: LumenSpacing.md
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.shape = shape
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer {
                content
                    .padding(padding)
                    .glassEffect(glassStyle, in: clipShapeView)
            }
        } else {
            content
                .padding(padding)
                .background(.regularMaterial, in: clipShapeView)
                .clipShape(clipShapeView)
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    private var glassStyle: Glass {
        switch style {
        case .regular:
            return .regular
        case .interactive:
            return .regular.interactive()
        case .prominent:
            return .regular.tint(.accentColor)
        }
    }

    private var clipShapeView: AnyShape {
        switch shape {
        case .rectangle:
            AnyShape(Rectangle())
        case .capsule:
            AnyShape(Capsule())
        case .roundedRectangle(let radius):
            AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

extension View {
    @ViewBuilder
    func glassCard(
        radius: CGFloat = LumenRadius.md,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
                .glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        } else {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: LumenSpacing.lg) {
            GlassContainer(style: .regular) {
                Text("Regular Glass")
            }
            GlassContainer(style: .interactive, shape: .capsule) {
                Text("Interactive Capsule")
            }
        }
        .padding()
    }
}
