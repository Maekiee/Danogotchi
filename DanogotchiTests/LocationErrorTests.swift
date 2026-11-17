import XCTest
@testable import Danogotchi

final class LocationErrorTests: XCTestCase {
    func test_everyCaseHasFixedDomainAndCode() {
        let cases: [(LocationError, Int)] = [(.permissionDenied, 1), (.requestInProgress, 2)]
        for (error, code) in cases {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "danogotchi.location")
            XCTAssertEqual(nsError.code, code, "\(error)")
        }
    }
}
