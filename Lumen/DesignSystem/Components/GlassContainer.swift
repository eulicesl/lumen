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
        content
            .padding(padding)
            .background(backgroundMaterial)
            .clipShape(clipShapeView)
    }

    @ViewBuilder
    private var backgroundMaterial: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            switch style {
            case .regular:
                Rectangle()
                    .fill(.clear)
                    .glassEffect()
            case .interactive:
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.interactive)
            case .prominent:
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.prominent)
            }
        } else {
            Rectangle().fill(.regularMaterial)
        }
    }

    @ViewBuilder
    private var clipShapeView: some InsettableShape {
        switch shape {
        case .rectangle:
            Rectangle()
        case .capsule:
            Capsule()
        case .roundedRectangle(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
        }
    }
}

extension View {
    func glassCard(radius: CGFloat = LumenRadius.md) -> some View {
        self.background {
            if #available(iOS 26.0, macOS 26.0, *) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.clear)
                    .glassEffect()
            } else {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.regularMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
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
