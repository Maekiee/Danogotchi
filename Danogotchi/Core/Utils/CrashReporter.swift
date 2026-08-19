import Foundation
import FirebaseCrashlytics

enum CrashReporter {
    /// 예외/에러 객체가 있는 실패 지점에서 비정상(non-fatal) 기록.
    static func record(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    /// Error 객체 없이 "발생해선 안 되는 상태"만 감지된 경우의 기록.
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
}
