import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.maekie.Danogotchi"
    /// 화면 생성/해제 트레이스
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
    /// CoreData 저장·시드
    static let database = Logger(subsystem: subsystem, category: "Database")
    /// Unsplash 등 원격 통신
    static let network = Logger(subsystem: subsystem, category: "Network")
    /// FCM 토큰·푸시
    static let push = Logger(subsystem: subsystem, category: "Push")
    /// 탭·메일 컴포저 등 UI 이벤트
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
