import CoreData
import Foundation
import FirebaseCrashlytics

enum CrashReporter {
    /// Crashlytics로 보내도 되는 userInfo 키. 이 목록 밖의 값은 보내기 전에 버린다
    enum InfoKey {
        static let httpStatus = "http_status"
        static let urlErrorCode = "url_error_code"
        static let decodingKind = "decoding_kind"
        static let codingPath = "coding_path"
        static let underlyingDomain = "underlying_domain"
        static let underlyingCode = "underlying_code"
        static let hangDurationMs = "hang_duration_ms"
        static let appBuildVersion = "app_build_version"

        /// 위 앱 키와, 값이 숫자·키 이름뿐인 Core Data 시스템 키(실패 원인 파악용)
        fileprivate static let allowed: Set<String> = [
            httpStatus, urlErrorCode, decodingKind, codingPath, hangDurationMs, appBuildVersion,
            NSSQLiteErrorDomain, NSValidationKeyErrorKey
        ]
    }

    /// Crashlytics custom key 이름. 값의 종류가 적은 것만 둔다
    enum CustomKey: String {
        case currentScreen = "current_screen"
        case networkType = "network_type"
        case lowPowerMode = "low_power_mode"
        case appLanguage = "app_language"
        case vocabCountBucket = "vocab_count_bucket"
        case petStage = "pet_stage"
    }

    /// 기록 여부 판단. 앱 타입을 아는 정책은 App이 시작 시 한 번 넣는다
    static var shouldRecord: (Error) -> Bool = { _ in true }

    /// 익명 설치 ID만 넣는다 — 기기 식별자·개인정보는 쓰지 않는다
    static func setUserID(_ id: String) {
        Crashlytics.crashlytics().setUserID(id)
    }

    static func setValue(_ value: Any, for key: CustomKey) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key.rawValue)
    }

    /// 화면 breadcrumb와 current_screen을 같은 이름으로 함께 갱신한다
    static func screenDidAppear(_ name: String) {
        log("screen: \(name)")
        setValue(name, for: .currentScreen)
    }

    /// 예외/에러 객체가 있는 실패 지점에서 비정상(non-fatal) 기록.
    static func record(_ error: Error) {
        guard shouldRecord(error) else { return }
        Crashlytics.crashlytics().record(error: sanitized(error))
    }

    /// 일어나면 안 되는 상태의 기록. 지점마다 다른 이슈로 묶이도록 이름을 domain에 넣는다
    static func recordInvariantViolation(_ name: StaticString) {
        record(NSError(domain: "danogotchi.invariant.\(name)", code: 0))
    }

    /// breadcrumb용 맥락 로그. 같은 세션의 다음 크래시·non-fatal 보고서에 붙을 뿐 단독으로는 남지 않는다
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// SDK가 userInfo 값을 description째 보낸다 — 시스템 에러에는 요청 URL·관리 객체 값이 들어 있어 허용 키만 남긴다
    static func sanitized(_ error: Error) -> NSError {
        let nsError = error as NSError
        var userInfo = nsError.userInfo.filter { InfoKey.allowed.contains($0.key) }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            userInfo[NSUnderlyingErrorKey] = NSError(domain: underlying.domain, code: underlying.code)
            userInfo[InfoKey.underlyingDomain] = underlying.domain
            userInfo[InfoKey.underlyingCode] = underlying.code
        }
        return NSError(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
    }
}
