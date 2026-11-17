import XCTest
@testable import Danogotchi

final class PersistenceErrorTests: XCTestCase {
    func test_everyCaseHasFixedDomainAndCode() {
        let nsError = PersistenceError.entityNotFound as NSError
        XCTAssertEqual(nsError.domain, "danogotchi.persistence")
        XCTAssertEqual(nsError.code, 1)
    }
}
