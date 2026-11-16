import CoreData
import XCTest
@testable import Danogotchi

final class CrashReporterTests: XCTestCase {
    func test_sanitizedDropsRequestURLAndKeepsAllowedKeys() throws {
        let secretURL = "https://api.example.test/weather?lat=37.5&lon=127.0&appid=SECRET"
        let urlError = URLError(.timedOut, userInfo: [
            NSURLErrorFailingURLStringErrorKey: secretURL,
            NSLocalizedDescriptionKey: "요청 \(secretURL) 시간 초과"
        ])

        let sanitized = CrashReporter.sanitized(NetworkError.transport(urlError))

        XCTAssertEqual(sanitized.domain, "danogotchi.network")
        XCTAssertEqual(sanitized.code, 2)
        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.urlErrorCode] as? Int, URLError.timedOut.rawValue)
        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.underlyingDomain] as? String, NSURLErrorDomain)
        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.underlyingCode] as? Int, URLError.timedOut.rawValue)
        let underlying = try XCTUnwrap(sanitized.userInfo[NSUnderlyingErrorKey] as? NSError)
        XCTAssertTrue(underlying.userInfo.isEmpty, "원인 에러는 domain/code만 남긴다")
        // SDK는 값을 description째 보낸다 — 보내는 문자열 어디에도 URL이 없어야 한다
        for value in sanitized.userInfo.values {
            XCTAssertFalse(String(describing: value).contains("SECRET"))
            XCTAssertFalse(String(describing: value).contains("lat="))
        }
    }

    func test_sanitizedDropsManagedObjectValuesButKeepsCoreDataCodes() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSValidationMissingMandatoryPropertyError, userInfo: [
            NSValidationObjectErrorKey: "<VocabEntity word=apple meaning=사과>",
            NSValidationKeyErrorKey: "meaning",
            NSSQLiteErrorDomain: 13
        ])

        let sanitized = CrashReporter.sanitized(error)

        XCTAssertEqual(sanitized.domain, NSCocoaErrorDomain)
        XCTAssertEqual(sanitized.code, NSValidationMissingMandatoryPropertyError)
        XCTAssertNil(sanitized.userInfo[NSValidationObjectErrorKey])
        XCTAssertEqual(sanitized.userInfo[NSValidationKeyErrorKey] as? String, "meaning")
        XCTAssertEqual(sanitized.userInfo[NSSQLiteErrorDomain] as? Int, 13)
    }

    func test_sanitizedKeepsDecodingKindAndPathWithoutValues() {
        let context = DecodingError.Context(
            codingPath: [StubKey("main"), StubKey("temp")], debugDescription: "found 'abc' instead of number"
        )

        let sanitized = CrashReporter.sanitized(NetworkError.decoding(.typeMismatch(Double.self, context)))

        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.decodingKind] as? String, "typeMismatch")
        XCTAssertEqual(sanitized.userInfo[CrashReporter.InfoKey.codingPath] as? String, "main.temp")
        XCTAssertFalse(sanitized.userInfo.values.contains { String(describing: $0).contains("abc") })
    }
}

private struct StubKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}
