import XCTest
@testable import Danogotchi

final class HangDiagnosticsReporterTests: XCTestCase {
    func test_hangBecomesFixedDomainWithDurationAndBuildInUserInfo() {
        let error = HangDiagnosticsReporter.error(
            hangDuration: Measurement(value: 2.5, unit: .seconds), buildVersion: "42"
        )

        XCTAssertEqual(error.domain, "danogotchi.metrickit.hang")
        XCTAssertEqual(error.code, 0, "시간·빌드가 달라도 같은 이슈로 묶인다")
        XCTAssertEqual(error.userInfo[CrashReporter.InfoKey.hangDurationMs] as? Int, 2_500)
        XCTAssertEqual(error.userInfo[CrashReporter.InfoKey.appBuildVersion] as? String, "42")
    }

    func test_fractionalMillisecondsAreRounded() {
        let error = HangDiagnosticsReporter.error(
            hangDuration: Measurement(value: 1_234.6, unit: .milliseconds), buildVersion: "1"
        )

        XCTAssertEqual(error.userInfo[CrashReporter.InfoKey.hangDurationMs] as? Int, 1_235)
    }

    /// 정화 단계가 허용 키만 남기므로 hang 키가 허용 목록에 있어야 전송된다
    func test_sanitizedKeepsHangKeys() {
        let error = HangDiagnosticsReporter.error(hangDuration: Measurement(value: 3, unit: .seconds), buildVersion: "7")

        let sanitized = CrashReporter.sanitized(error)

        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.hangDurationMs] as? Int, 3_000)
        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.appBuildVersion] as? String, "7")
    }
}
