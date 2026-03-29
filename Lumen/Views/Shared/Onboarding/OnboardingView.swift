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
        pageContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundGradient)
            .safeAreaInset(edge: .bottom) {
                controls
                    .padding(.horizontal, LumenSpacing.xl)
                    .padding(.top, LumenSpacing.md)
                    .padding(.bottom, LumenSpacing.lg)
                    .background(.ultraThinMaterial)
            }
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
                }

                VStack(spacing: LumenSpacing.md) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
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
            .padding(.top, LumenSpacing.xl)
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

                    Spacer()

                    Button {
                        withAnimation { currentPage += 1 }
                        HapticEngine.impact(.light)
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, LumenSpacing.xl)
                            .padding(.vertical, LumenSpacing.md)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
            } else {
                Button {
                    HapticEngine.notification(.success)
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LumenSpacing.md)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: LumenRadius.lg))
                }
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
