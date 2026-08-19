import UIKit
import OSLog
import FirebaseCore
import FirebaseMessaging
import IQKeyboardManagerSwift


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        FirebaseApp.configure()

        IQKeyboardManager.shared.isEnabled = true
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        // 토큰 원문은 남기지 않는다 — 로그로 유출되면 임의 기기에 푸시를 보낼 수 있다
        Messaging.messaging().token { token, error in
            if let error = error {
                AppLogger.push.error("FCM 토큰 조회 실패: \(String(describing: error), privacy: .public)")
                CrashReporter.record(error)
            } else if token != nil {
                AppLogger.push.debug("FCM 토큰 조회 성공")
            }
        }
        
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //        deviceToken
    //    }
}

extension AppDelegate: MessagingDelegate {
    
    // 디바이스 토큰 정보가 변견ㅇ이 되면 알려줌
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        AppLogger.push.debug("FCM 등록 토큰 갱신 (수신: \(fcmToken != nil, privacy: .public))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
