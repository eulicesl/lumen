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
        subtitle: "A privacy-first AI assistant that runs entirely on your device and local network — no data ever leaves your hands."
    ),
    OnboardingPage(
        id: 1,
        symbol: "lock.shield.fill",
        symbolColor: .green,
        title: "Your Privacy, Guaranteed",
        subtitle: "Lumen uses Apple Intelligence and Ollama — both run on-device or on your local network. No cloud accounts. No tracking. Your conversations stay yours."
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
        subtitle: "Connect Ollama on your local network or use Apple Intelligence on this device. Switch models anytime from the chat bar."
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

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
        .animation(.easeInOut(duration: 0.35), value: currentPage)
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LumenSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(page.symbolColor.opacity(0.12))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(page.symbolColor.opacity(0.06))
                        .frame(width: 180, height: 180)

                    Image(systemName: page.symbol)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(page.symbolColor)
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                        .accessibilityHidden(true)
                }

                VStack(spacing: LumenSpacing.md) {
                    Text(page.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

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
                    .accessibilityHint("Skips onboarding and opens the app")

                    Spacer()

                    Button {
                        withAnimation { currentPage += 1 }
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
                    .animation(.spring(duration: 0.3), value: currentPage)
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
        .animation(.easeInOut(duration: 0.4), value: currentPage)
    }

    private func completeOnboarding() {
        withAnimation(.easeOut(duration: 0.3)) {
            hasSeenOnboarding = true
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
