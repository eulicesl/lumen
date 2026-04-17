import Foundation
import SwiftUI
import Vision
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

actor ImageService {
    static let shared = ImageService()

    private init() {}

    // MARK: - Resize for API

    func prepareForAPI(_ image: PlatformImage, maxDimension: CGFloat = 1024) async -> Data? {
        let resized = await Task.detached(priority: .userInitiated) {
            ImageService.resize(image, maxDimension: maxDimension)
        }.value
        return resized?.platformJPEGData(compressionQuality: 0.8)
    }

    func prepareAllForAPI(_ images: [PlatformImage], maxDimension: CGFloat = 1024) async -> [Data] {
        var results: [Data] = []
        for image in images {
            if let data = await prepareForAPI(image, maxDimension: maxDimension) {
                results.append(data)
            }
        }
        return results
    }

    // MARK: - OCR

    func extractText(from image: PlatformImage) async throws -> String {
        guard let cgImage = image.platformCGImage else { return "" }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Thumbnail

    func makeThumbnail(from image: PlatformImage, size: CGSize = CGSize(width: 80, height: 80)) async -> PlatformImage? {
        await Task.detached(priority: .userInitiated) {
            image.renderedImage(at: size)
        }.value
    }

    // MARK: - Private helpers

    private static func resize(_ image: PlatformImage, maxDimension: CGFloat) -> PlatformImage? {
        let size = image.platformSize
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return image.renderedImage(at: newSize)
    }
}

// MARK: - Data → PlatformImage helper

extension Data {
    var asPlatformImage: PlatformImage? { PlatformImage(data: self) }
}

private extension PlatformImage {
    var platformCGImage: CGImage? {
        #if canImport(UIKit)
        return self.cgImage
        #else
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
        #endif
    }

    var platformSize: CGSize {
        size
    }

    func platformJPEGData(compressionQuality: CGFloat) -> Data? {
        #if canImport(UIKit)
        return self.jpegData(compressionQuality: compressionQuality)
        #else
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #endif
    }

    func renderedImage(at size: CGSize) -> PlatformImage? {
        #if canImport(UIKit)
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        #else
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        return image
        #endif
    }
}
