import SwiftUI
import PhotosUI

struct ImageAttachmentRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var images: [PlatformImage]
    var onOCR: ((PlatformImage) -> Void)? = nil
    @ScaledMetric(relativeTo: .body) private var removeIconSize = 18


    var body: some View {
        if !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LumenSpacing.sm) {
                    ForEach(images.indices, id: \.self) { i in
                        attachmentThumbnail(image: images[i], index: i)
                    }
                }
                .padding(.horizontal, LumenSpacing.md)
                .padding(.vertical, LumenSpacing.xs)
            }
            .frame(height: 96)
            .background(.bar)
            .transition(LumenMotion.moveTransition(edge: .bottom, reduceMotion: reduceMotion))
        }
    }

    private func attachmentThumbnail(image: PlatformImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(platformImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: LumenRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: LumenRadius.md)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )
                .contextMenu {
                    if let onOCR {
                        Button {
                            onOCR(image)
                        } label: {
                            Label("Extract Text (OCR)", systemImage: "text.viewfinder")
                        }
                    }
                    Button(role: .destructive) {
                        images.remove(at: index)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
                .accessibilityLabel("Attached image \(index + 1)")
                .accessibilityHint("Shows an attached image for the current message")

            Button {
                images.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: removeIconSize))
                    .foregroundStyle(.white)
                    .background(Color.black.opacity(0.5), in: Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
            .accessibilityLabel("Remove attached image \(index + 1)")
            .accessibilityHint("Removes this image from the message")
        }
    }
}

// MARK: - Photo picker button

struct PhotoPickerButton: View {
    @Binding var selectedImages: [PlatformImage]
    @State private var pickerItems: [PhotosPickerItem] = []
    var maxSelection: Int = 4
    @ScaledMetric(relativeTo: .body) private var actionIconSize = 20


    var body: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: maxSelection,
            matching: .images
        ) {
            Image(systemName: LumenIcon.photo)
                .font(.system(size: actionIconSize))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Attach photos")
        .accessibilityHint("Opens the photo picker to attach images")
        .onChange(of: pickerItems) {
            Task { await loadImages() }
        }
    }

    private func loadImages() async {
        var loaded: [PlatformImage] = []
        for item in pickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = PlatformImage(data: data) {
                loaded.append(image)
            }
        }
        if !loaded.isEmpty {
            selectedImages = loaded
        }
        pickerItems = []
    }
}

// MARK: - Camera capture button (iOS only)

#if os(iOS)
struct CameraButton: View {
    @Binding var capturedImage: PlatformImage?
    @State private var showingCamera = false
    @ScaledMetric(relativeTo: .body) private var actionIconSize = 20


    var body: some View {
        Button {
            showingCamera = true
        } label: {
            Image(systemName: LumenIcon.camera)
                .font(.system(size: actionIconSize))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take photo")
        .accessibilityHint("Opens the camera to capture an image")
        .sheet(isPresented: $showingCamera) {
            CameraPickerView(image: $capturedImage)
                .ignoresSafeArea()
        }
    }
}

// MARK: - UIImagePickerController wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: PlatformImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#if os(iOS)
private struct ImageAttachmentRowPreviewHost: View {
    @State private var images: [PlatformImage] = [
        .preview(color: .systemBlue),
        .preview(color: .systemTeal)
    ]
    @State private var capturedImage: PlatformImage? = .preview(color: .systemOrange)

    var body: some View {
        VStack(alignment: .leading, spacing: LumenSpacing.md) {
            ImageAttachmentRow(images: $images)

            HStack(spacing: LumenSpacing.md) {
                PhotoPickerButton(selectedImages: $images)
                CameraButton(capturedImage: $capturedImage)
            }
        }
        .padding()
        .background(LumenColor.primaryBackground)
    }
}
#endif

#if os(iOS)
private extension PlatformImage {
    static func preview(color: PlatformColor) -> PlatformImage {
        UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
        }
    }
}
#endif

#if os(iOS)
#Preview("Attachments") {
    ImageAttachmentRowPreviewHost()
}
#endif
