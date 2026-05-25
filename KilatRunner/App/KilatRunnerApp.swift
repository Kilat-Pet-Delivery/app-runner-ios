import SwiftUI
import UIKit
import UserNotifications

@main
struct KilatRunnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = AppSession()
    @State private var deepLinkRouter = DeepLinkRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(deepLinkRouter)
                .onAppear {
                    appDelegate.configure(router: deepLinkRouter)
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let pushService = PushNotificationService.shared
    private var deepLinkRouter = DeepLinkRouter.shared

    func configure(router: DeepLinkRouter) {
        deepLinkRouter = router
        UNUserNotificationCenter.current().delegate = self
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let intent = pushService.decodeIntent(userInfo: userInfo) {
            Task { @MainActor in
                deepLinkRouter.publish(intent)
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("Kilat APNs token registered: \(token)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let intent = pushService.decodeIntent(userInfo: response.notification.request.content.userInfo) else {
            return
        }
        await MainActor.run {
            deepLinkRouter.publish(intent)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
