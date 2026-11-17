import CoreLocation
import UserNotifications
import XCTest
@testable import Danogotchi

final class CrashReportPolicyTests: XCTestCase {
    /// FIRFirestoreErrors.h의 값 — 테스트 타깃은 Firestore를 링크하지 않는다
    private let firestoreDomain = "FIRFirestoreErrorDomain"
    private let firestoreUnavailable = 14
    private let firestorePermissionDenied = 7

    func test_expectedFlowFailuresAreNotRecorded() {
        let expected: [(String, Error)] = [
            ("취소", CancellationError()),
            ("URL 취소", URLError(.cancelled)),
            ("인터넷 없음", URLError(.notConnectedToInternet)),
            ("연결 끊김", URLError(.networkConnectionLost)),
            ("셀룰러 데이터 꺼짐", URLError(.dataNotAllowed)),
            ("로밍 꺼짐", URLError(.internationalRoamingOff)),
            ("감싼 인터넷 없음", NetworkError.transport(URLError(.notConnectedToInternet))),
            ("감싼 URL 취소", NetworkError.transport(URLError(.cancelled))),
            ("위치 권한 거부", LocationError.permissionDenied),
            ("CoreLocation 권한 거부", CLError(.denied)),
            ("일시적 위치 실패", CLError(.locationUnknown)),
            ("알림 권한 없음", UNError(.notificationsNotAllowed)),
            ("Firestore 오프라인", NSError(domain: firestoreDomain, code: firestoreUnavailable))
        ]
        for (name, error) in expected {
            XCTAssertFalse(CrashReportPolicy.shouldRecord(error), name)
        }
    }

    func test_realFailuresAreRecorded() {
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "test"))
        let recorded: [(String, Error)] = [
            ("디코딩", NetworkError.decoding(decoding)),
            ("5xx", NetworkError.serviceUnavailable(statusCode: 503)),
            ("정의되지 않은 상태 코드", NetworkError.unknown(NSError(domain: "HTTPStatus", code: 418))),
            ("타임아웃", NetworkError.transport(URLError(.timedOut))),
            ("Core Data 쓰기", CocoaError(.fileWriteOutOfSpace)),
            ("Core Data 읽기", CocoaError(.fileReadUnknown)),
            ("위치 요청 중복", LocationError.requestInProgress),
            ("CoreLocation 네트워크", CLError(.network)),
            ("Firestore 권한", NSError(domain: firestoreDomain, code: firestorePermissionDenied)),
            ("DB 준비", DatabasePreparationError(stage: .seed, underlying: CocoaError(.fileWriteOutOfSpace)))
        ]
        for (name, error) in recorded {
            XCTAssertTrue(CrashReportPolicy.shouldRecord(error), name)
        }
    }
}
