import Foundation
import SwiftUI
import Vision

actor ImageService {
    static let shared = ImageService()

    private init() {}

    // MARK: - Resize for API

    func prepareForAPI(_ image: UIImage, maxDimension: CGFloat = 1024) async -> Data? {
        let resized = await Task.detached(priority: .userInitiated) {
            ImageService.resize(image, maxDimension: maxDimension)
        }.value
        return resized?.jpegData(compressionQuality: 0.8)
    }

    func prepareAllForAPI(_ images: [UIImage], maxDimension: CGFloat = 1024) async -> [Data] {
        var results: [Data] = []
        for image in images {
            if let data = await prepareForAPI(image, maxDimension: maxDimension) {
                results.append(data)
            }
        }
        return results
    }

    // MARK: - OCR

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }
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

    func makeThumbnail(from image: UIImage, size: CGSize = CGSize(width: 80, height: 80)) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            UIGraphicsImageRenderer(size: size).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }.value
    }

    // MARK: - Private helpers

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Data → UIImage helper

extension Data {
    var asPlatformImage: PlatformImage? { PlatformImage(data: self) }
}
