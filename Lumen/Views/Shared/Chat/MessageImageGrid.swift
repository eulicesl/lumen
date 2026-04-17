import SwiftUI

struct MessageImageGrid: View {
    let imageData: [Data]
    var maxVisible: Int = 4
    @State private var fullscreenIndex: Int? = nil

    var body: some View {
        let visible = Array(imageData.prefix(maxVisible))
        let extra = imageData.count - maxVisible

        LazyVGrid(columns: gridColumns(for: visible.count), spacing: LumenSpacing.xxs) {
            ForEach(visible.indices, id: \.self) { i in
                ZStack(alignment: .bottomTrailing) {
                    imageCell(data: visible[i])
                        .onTapGesture { fullscreenIndex = i }

                    if i == visible.count - 1 && extra > 0 {
                        Text("+\(extra)")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: LumenRadius.sm))
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LumenRadius.md))
        .frame(maxWidth: 280)
        .fullScreenCover(item: Binding(
            get: { fullscreenIndex.map { FullscreenID(index: $0) } },
            set: { fullscreenIndex = $0?.index }
        )) { item in
            FullscreenImageViewer(imageData: imageData, startIndex: item.index)
        }
    }

    @ViewBuilder
    private func imageCell(data: Data) -> some View {
        if let image = data.asPlatformImage {
            Image(platformImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .aspectRatio(1, contentMode: .fit)
        } else {
            RoundedRectangle(cornerRadius: LumenRadius.sm)
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fit)
                .overlay { Image(systemName: "photo").foregroundStyle(.tertiary) }
        }
    }

    private func gridColumns(for count: Int) -> [GridItem] {
        switch count {
        case 1:  return [GridItem(.flexible())]
        case 2:  return [GridItem(.flexible()), GridItem(.flexible())]
        default: return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
}

// MARK: - Fullscreen viewer

private struct FullscreenID: Identifiable {
    let index: Int
    var id: Int { index }
}

struct FullscreenImageViewer: View {
    let imageData: [Data]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(imageData: [Data], startIndex: Int) {
        self.imageData = imageData
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentIndex) {
                ForEach(imageData.indices, id: \.self) { i in
                    if let image = imageData[i].asPlatformImage {
                        Image(platformImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(i)
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                    .accessibilityLabel("Close image viewer")
                    .accessibilityHint("Returns to the conversation")
                }
                Spacer()
            }
        }
    }
}

#Preview {
    MessageImageGrid(imageData: [])
}
