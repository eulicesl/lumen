#if os(iOS)
import SwiftUI

struct VoiceWaveformView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isAnimating: Bool
    var barCount: Int = 5
    var color: Color = .accentColor

    @State private var levels: [CGFloat] = []
    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 4, height: barHeight(for: i))
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
        .frame(height: 40)
        .onAppear { setupLevels() }
        .onReceive(timer) { _ in
            guard !reduceMotion else { return }
            if isAnimating { randomizeLevels() }
            else { flattenLevels() }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if reduceMotion {
            return isAnimating ? 24 : 8
        }
        guard levels.indices.contains(index) else { return 8 }
        return isAnimating ? max(8, levels[index] * 40) : 8
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
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(isActive ? scale : 1.0)
                .opacity(isActive ? (reduceMotion ? 0.25 : opacity) : 0)

            Circle()
                .fill(Color.accentColor.opacity(0.25))
                .frame(width: 80, height: 80)

            Circle()
                .fill(Color.accentColor)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: isActive ? LumenIcon.micActive : LumenIcon.microphone)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
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
