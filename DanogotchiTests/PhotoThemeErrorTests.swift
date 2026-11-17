import XCTest
@testable import Danogotchi

final class PhotoThemeErrorTests: XCTestCase {
    func test_everyCaseHasFixedDomainAndCode() {
        let cases: [(PhotoThemeError, Int)] = [
            (.transferFailed, 1), (.unsupportedFormat, 2), (.encodingFailed, 3), (.invalidCrop, 4)
        ]
        for (error, code) in cases {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "danogotchi.photo_theme")
            XCTAssertEqual(nsError.code, code, "\(error)")
        }
    }
}
