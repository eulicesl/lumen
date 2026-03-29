import SwiftUI

struct TypingIndicator: View {

    @State private var animatingDot = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dotCount = 3
    private let dotSize: CGFloat = 7
    private let dotSpacing: CGFloat = 5
    private let animationInterval: TimeInterval = 0.3

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(LumenColor.secondaryText)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(scaleForDot(at: index))
                    .opacity(opacityForDot(at: index))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            startAnimation()
        }
        .accessibilityLabel("Generating response")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func scaleForDot(at index: Int) -> CGFloat {
        guard !reduceMotion else { return 1.0 }
        return animatingDot == index ? 1.3 : 1.0
    }

    private func opacityForDot(at index: Int) -> Double {
        guard !reduceMotion else { return 0.5 }
        return animatingDot == index ? 1.0 : 0.4
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { _ in
            withAnimation(LumenAnimation.snappy) {
                animatingDot = (animatingDot + 1) % dotCount
            }
        }
    }
}

struct StreamingPulse: View {

    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: LumenSpacing.xxs) {
            Image(systemName: "sparkle")
                .imageScale(.small)
                .foregroundStyle(LumenColor.tint)
                .scaleEffect(isPulsing && !reduceMotion ? 1.2 : 1.0)
                .opacity(isPulsing ? 1.0 : 0.6)
                .animation(
                    reduceMotion ? .none :
                        Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )
            Text("Generating")
                .font(LumenType.messageCaption)
                .foregroundStyle(LumenColor.secondaryText)
        }
        .onAppear { isPulsing = true }
        .accessibilityLabel("Generating response")
    }
}

struct LoadingIndicator: View {

    enum IndicatorStyle {
        case typingDots
        case streamingPulse
        case spinner
    }

    let style: IndicatorStyle

    init(style: IndicatorStyle = .typingDots) {
        self.style = style
    }

    var body: some View {
        switch style {
        case .typingDots:
            TypingIndicator()
        case .streamingPulse:
            StreamingPulse()
        case .spinner:
            ProgressView()
                .controlSize(.regular)
                .tint(LumenColor.tint)
        }
    }
}

#Preview("Typing Indicator") {
    TypingIndicator()
        .padding()
}

#Preview("Streaming Pulse") {
    StreamingPulse()
        .padding()
}

#Preview("Loading Styles") {
    VStack(spacing: LumenSpacing.xxl) {
        LoadingIndicator(style: .typingDots)
        LoadingIndicator(style: .streamingPulse)
        LoadingIndicator(style: .spinner)
    }
    .padding()
}
