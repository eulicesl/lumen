import SwiftUI

// MARK: - Onboarding page model

private struct OnboardingPage: Identifiable {
    let id: Int
    let symbol: String
    let symbolColor: Color
    let title: String
    let subtitle: String
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        id: 0,
        symbol: "wand.and.stars",
        symbolColor: .accentColor,
        title: "Welcome to Lumen",
        subtitle: "A privacy-first AI assistant with Apple Intelligence on-device, plus optional Ollama Local and Ollama Cloud providers you control."
    ),
    OnboardingPage(
        id: 1,
        symbol: "lock.shield.fill",
        symbolColor: .green,
        title: "Your Privacy, Guaranteed",
        subtitle: "Apple Intelligence stays on-device. Ollama Local stays on infrastructure you control. Ollama Cloud is optional and only used when you enable it. No tracking. Your conversations stay yours."
    ),
    OnboardingPage(
        id: 2,
        symbol: "cpu.fill",
        symbolColor: .purple,
        title: "Powerful AI, Built In",
        subtitle: "Supports multiple AI models side-by-side, voice input, image analysis, smart memory, and an agent mode with built-in tools."
    ),
    OnboardingPage(
        id: 3,
        symbol: "sparkles",
        symbolColor: .orange,
        title: "Ready to Go",
        subtitle: "Choose Apple Intelligence, connect Ollama Local, or sign in with an Ollama Cloud API key. Switch models anytime from the chat bar."
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @ScaledMetric(relativeTo: .largeTitle) private var symbolCoreSize = 64
    @ScaledMetric(relativeTo: .largeTitle) private var innerCircleSize = 140
    @ScaledMetric(relativeTo: .largeTitle) private var outerCircleSize = 180

    var body: some View {
        VStack(spacing: 0) {
            pageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
                .padding(.horizontal, LumenSpacing.xl)
                .padding(.top, LumenSpacing.md)
                .padding(.bottom, LumenSpacing.lg)
                .background(.ultraThinMaterial)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .interactiveDismissDisabled()
    }

    // MARK: - Page content

    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(onboardingPages) { page in
                pageView(page)
                    .tag(page.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(
            LumenMotion.animation(.easeInOut(duration: 0.35), reduceMotion: reduceMotion),
            value: currentPage
        )
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LumenSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(page.symbolColor.opacity(0.12))
                        .frame(width: innerCircleSize, height: innerCircleSize)

                    Circle()
                        .fill(page.symbolColor.opacity(0.06))
                        .frame(width: outerCircleSize, height: outerCircleSize)

                    onboardingSymbol(for: page)
                }

                VStack(spacing: LumenSpacing.md) {
                    Text(page.title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(page.subtitle)
                        .font(LumenType.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, LumenSpacing.md)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LumenSpacing.xl)
            .padding(.top, LumenSpacing.xxl)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: LumenSpacing.lg) {
            pageIndicator

            if currentPage < onboardingPages.count - 1 {
                HStack {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(LumenType.body)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Skip onboarding")
                    .accessibilityHint("Skips onboarding and opens the app")

                    Spacer()

                    Button {
                        LumenMotion.perform(reduceMotion: reduceMotion) {
                            currentPage += 1
                        }
                        HapticEngine.impact(.light)
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                            .labelStyle(.titleAndIcon)
                            .font(LumenType.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, LumenSpacing.xl)
                            .padding(.vertical, LumenSpacing.md)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .accessibilityLabel("Next page")
                    .accessibilityHint("Moves to the next onboarding page")
                }
            } else {
                Button {
                    HapticEngine.notification(.success)
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(LumenType.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LumenSpacing.md)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: LumenRadius.lg))
                }
                .accessibilityLabel("Get started")
                .accessibilityHint("Completes onboarding and opens the app")
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(onboardingPages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(
                        LumenMotion.animation(.spring(duration: 0.3), reduceMotion: reduceMotion),
                        value: currentPage
                    )
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(currentPage + 1) of \(onboardingPages.count)")
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                onboardingPages[currentPage].symbolColor.opacity(0.06),
                Color.clear,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(
            LumenMotion.animation(.easeInOut(duration: 0.4), reduceMotion: reduceMotion),
            value: currentPage
        )
    }

    private func completeOnboarding() {
        LumenMotion.perform(.easeOut(duration: 0.3), reduceMotion: reduceMotion) {
            hasSeenOnboarding = true
        }
    }

    @ViewBuilder
    private func onboardingSymbol(for page: OnboardingPage) -> some View {
        let symbol = Image(systemName: page.symbol)
            .font(.system(size: symbolCoreSize, weight: .light))
            .foregroundStyle(page.symbolColor)
            .accessibilityHidden(true)

        if reduceMotion {
            symbol
        } else {
            symbol.symbolEffect(.pulse.byLayer, options: .repeating)
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
