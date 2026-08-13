import Foundation
import OSLog

/// 프로젝트 전역 로깅 진입점. `print` 대신 항상 이 타입을 쓴다.
///
/// subsystem은 번들 ID라서 Dev(`com.maekie.Danogotchi.dev`)와 Release(`com.maekie.Danogotchi`) 로그가
/// Console.app에서 자동으로 분리된다.
///
/// 레벨 기준:
/// - `.debug` — 개발용 트레이스. 릴리스에서는 기본 수집되지 않으므로 `#if DEBUG` 가드가 필요 없다.
/// - `.error` — 실패(저장 실패 / 통신 실패 등).
///
/// privacy 기준: OSLog는 문자열·객체 보간을 기본 `<private>`로 가린다.
/// 진단에 필요한 에러 상세만 `privacy: .public`을 명시하고, 사용자 데이터(단어·검색어)는 기본값을 유지한다.
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
