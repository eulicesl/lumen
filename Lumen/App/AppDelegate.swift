import UIKit
import BackgroundTasks

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerBackgroundTasks()
        return true
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        handleDeepLink(url)
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if let url = userActivity.webpageURL {
            handleDeepLink(url)
        }
        return true
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lumen.spotlight-index",
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self.handleSpotlightIndexRefresh(task: refreshTask)
        }
    }

    private func handleSpotlightIndexRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        scheduleSpotlightIndexRefresh()
        task.setTaskCompleted(success: true)
    }

    private func scheduleSpotlightIndexRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.lumen.spotlight-index")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 6)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleDeepLink(_ url: URL) {
        NotificationCenter.default.post(
            name: .lumenDeepLink,
            object: nil,
            userInfo: ["url": url]
        )
    }
}

extension Notification.Name {
    static let lumenDeepLink = Notification.Name("com.lumen.deepLink")
}
