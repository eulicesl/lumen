#if os(iOS)
import SwiftUI

private enum VoiceWaveformMetrics {
    static let barSpacing: CGFloat = 4
    static let barCornerRadius: CGFloat = 3
    static let barWidth: CGFloat = 4
    static let idleBarHeight: CGFloat = 8
    static let reducedMotionActiveBarHeight: CGFloat = 24
    static let waveformHeight: CGFloat = 40
}

struct VoiceWaveformView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isAnimating: Bool
    var barCount: Int = 5
    var color: Color = .accentColor

    @State private var levels: [CGFloat] = []
    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: VoiceWaveformMetrics.barSpacing) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: VoiceWaveformMetrics.barCornerRadius)
                    .fill(color)
                    .frame(width: VoiceWaveformMetrics.barWidth, height: barHeight(for: i))
                    .animation(
                        LumenMotion.animation(
                            isAnimating
                                ? .easeInOut(duration: 0.15).delay(Double(i) * 0.02)
                                : .easeOut(duration: 0.2),
                            reduceMotion: reduceMotion
                        ),
                        value: levels.indices.contains(i) ? levels[i] : 0
                )
            }
        }
        .frame(height: VoiceWaveformMetrics.waveformHeight)
        .onAppear { setupLevels() }
        .onReceive(timer) { _ in
            guard !reduceMotion else { return }
            if isAnimating { randomizeLevels() }
            else { flattenLevels() }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if reduceMotion {
            return isAnimating
                ? VoiceWaveformMetrics.reducedMotionActiveBarHeight
                : VoiceWaveformMetrics.idleBarHeight
        }
        guard levels.indices.contains(index) else { return VoiceWaveformMetrics.idleBarHeight }
        return isAnimating
            ? max(VoiceWaveformMetrics.idleBarHeight, levels[index] * VoiceWaveformMetrics.waveformHeight)
            : VoiceWaveformMetrics.idleBarHeight
    }

    private func setupLevels() {
        levels = (0..<barCount).map { _ in CGFloat.random(in: 0.2...0.8) }
    }

    private func randomizeLevels() {
        LumenMotion.perform(reduceMotion: reduceMotion) {
            levels = (0..<barCount).map { _ in CGFloat.random(in: 0.2...1.0) }
        }
    }

    private func flattenLevels() {
        LumenMotion.perform(reduceMotion: reduceMotion) {
            levels = (0..<barCount).map { _ in 0.2 }
        }
    }
}

// MARK: - Circular pulsing indicator

struct VoicePulseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isActive: Bool
    @ScaledMetric(relativeTo: .title2) private var iconSize = 24
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(isActive ? scale : 1.0)
                .opacity(isActive ? opacity : 0)

            Circle()
                .fill(Color.accentColor.opacity(0.25))
                .frame(width: 80, height: 80)

            Circle()
                .fill(Color.accentColor)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: isActive ? LumenIcon.micActive : LumenIcon.microphone)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
        }
        .onAppear { updatePulseState() }
        .onChange(of: isActive) { updatePulseState() }
        .onChange(of: reduceMotion) { updatePulseState() }
    }

    private func updatePulseState() {
        if reduceMotion {
            scale = 1.0
            opacity = isActive ? 0.25 : 0.0
            return
        }

        if isActive {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.25
                opacity = 0.0
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.0
                opacity = 0.6
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        VoiceWaveformView(isAnimating: true)
        VoiceWaveformView(isAnimating: false)
        VoicePulseView(isActive: true)
    }
    .padding()
}
#endif
