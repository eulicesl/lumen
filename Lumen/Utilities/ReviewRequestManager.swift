import Foundation
import StoreKit
#if os(iOS)
import UIKit
#endif

// MARK: - ReviewRequestManager

/// Requests an App Store review at key interaction milestones.
/// Only prompts once per app version to respect Apple's rate limits.
@MainActor
final class ReviewRequestManager {
    static let shared = ReviewRequestManager()

    private let sendCountKey = "lumen.review.sendCount"
    private let lastVersionKey = "lumen.review.lastPromptedVersion"
    private let milestones: Set<Int> = [5, 25, 100]

    private init() {}

    // MARK: - Public

    /// Call after each successful AI response is completed.
    func recordSuccessfulResponse() {
        let current = sendCount + 1
        UserDefaults.standard.set(current, forKey: sendCountKey)

        guard milestones.contains(current),
              currentVersion != lastPromptedVersion else { return }

        requestReview()
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    }

    /// Reset for testing (debug only).
    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: sendCountKey)
        UserDefaults.standard.removeObject(forKey: lastVersionKey)
    }

    /// Immediately show the review prompt (for Settings "Rate Lumen" button).
    func requestReviewNow() {
        guard currentVersion != lastPromptedVersion else { return }
        requestReview()
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    }

    // MARK: - Private

    private var sendCount: Int {
        UserDefaults.standard.integer(forKey: sendCountKey)
    }

    private var lastPromptedVersion: String {
        UserDefaults.standard.string(forKey: lastVersionKey) ?? ""
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func requestReview() {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
        #elseif os(macOS)
        SKStoreReviewController.requestReview()
        #endif
    }
}
