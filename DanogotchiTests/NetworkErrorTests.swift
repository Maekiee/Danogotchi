import XCTest
@testable import Danogotchi

final class NetworkErrorTests: XCTestCase {
    /// code는 Crashlytics 이슈 묶음 기준이라 case 순서가 바뀌어도 그대로여야 한다
    func test_everyCaseHasFixedDomainAndCode() {
        let decoding = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        let cases: [(NetworkError, Int)] = [
            (.invalidURL, 1),
            (.transport(URLError(.timedOut)), 2),
            (.unauthorized, 3),
            (.badRequest(message: []), 4),
            (.forbidden(message: []), 5),
            (.notFound(message: []), 6),
            (.serviceUnavailable(statusCode: 503), 7),
            (.decoding(decoding), 8),
            (.unknown(NSError(domain: "HTTPStatus", code: 418)), 9)
        ]
        for (error, code) in cases {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "danogotchi.network")
            XCTAssertEqual(nsError.code, code, "\(error)")
        }
    }

    func test_statusCodeAndServerMessagesGoOnlyWhereExpected() {
        let unavailable = NetworkError.serviceUnavailable(statusCode: 503) as NSError
        XCTAssertEqual(unavailable.userInfo[CrashReporter.InfoKey.httpStatus] as? Int, 503)

        let badRequest = NetworkError.badRequest(message: ["query=검색어"]) as NSError
        XCTAssertTrue(badRequest.userInfo.isEmpty, "서버 메시지는 요청 값을 되돌려줄 수 있어 넣지 않는다")
    }
}
