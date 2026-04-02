import SwiftUI

struct ProviderMark: View {
    let provider: AIProviderType
    var size: CGFloat = 16
    var showsVariantBadge = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            markBody
                .frame(width: size, height: size)

            if showsVariantBadge, let badgeName = provider.badgeIconName {
                Image(systemName: badgeName)
                    .font(.system(size: max(7, size * 0.34), weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(3)
                    .background(Color(.systemBackground), in: Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
                    .offset(x: 4, y: 4)
            }
        }
        .frame(width: size + (showsVariantBadge ? 8 : 0), height: size + (showsVariantBadge ? 8 : 0))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var markBody: some View {
        switch provider {
        case .foundationModels:
            Image(systemName: LumenIcon.appleIntelligence)
                .font(.system(size: size * 0.9, weight: .semibold))
                .foregroundStyle(.primary)
        case .ollamaLocal, .ollamaCloud:
            Image("OllamaMark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(width: size * 0.72, height: size)
        }
    }
}

#Preview {
    HStack(spacing: LumenSpacing.lg) {
        ProviderMark(provider: .foundationModels, size: 18)
        ProviderMark(provider: .ollamaLocal, size: 18, showsVariantBadge: true)
        ProviderMark(provider: .ollamaCloud, size: 18, showsVariantBadge: true)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
