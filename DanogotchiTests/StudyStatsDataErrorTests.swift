import XCTest
@testable import Danogotchi

final class StudyStatsDataErrorTests: XCTestCase {
    func test_everyCaseHasFixedDomainAndCode() {
        let cases: [(StudyStatsDataError, Int)] = [
            (.invalidRecord, 1), (.conflictingAnswer, 2), (.conflictingSession, 3), (.invalidIdentifiers, 4)
        ]
        for (error, code) in cases {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "danogotchi.study_stats_data")
            XCTAssertEqual(nsError.code, code, "\(error)")
        }
    }
}
