import XCTest
@testable import Danogotchi

final class DatabasePreparationErrorTests: XCTestCase {
    func test_taggingWrapsFailureWithStageAndKeepsCause() throws {
        let cause = CocoaError(.fileWriteOutOfSpace)

        XCTAssertThrowsError(try DatabasePreparationError.tagging(.seed) { throw cause }) { error in
            let tagged = error as? DatabasePreparationError
            XCTAssertEqual(tagged?.stage, .seed)
            XCTAssertEqual(tagged?.underlying as? CocoaError, cause)
        }
        XCTAssertEqual(try DatabasePreparationError.tagging(.seed) { 7 }, 7)
    }

    /// 스택 로드(loadStore) 안에서 preflight 클로저가 실패해도 preflight로 남아야 한다
    func test_outerTaggingKeepsInnerStage() {
        XCTAssertThrowsError(try DatabasePreparationError.tagging(.loadStore) {
            try DatabasePreparationError.tagging(.preflight) { throw StudyStatsDataError.invalidIdentifiers }
        }) { error in
            XCTAssertEqual((error as? DatabasePreparationError)?.stage, .preflight)
        }
    }

    func test_stageIsFixedCodeAndCauseIsUnderlyingError() throws {
        let stages: [(DatabasePreparationError.Stage, Int)] = [(.preflight, 1), (.loadStore, 2), (.backfill, 3), (.seed, 4)]
        for (stage, code) in stages {
            let nsError = DatabasePreparationError(stage: stage, underlying: CocoaError(.fileReadUnknown)) as NSError
            XCTAssertEqual(nsError.domain, "danogotchi.database_preparation")
            XCTAssertEqual(nsError.code, code)
            let underlying = try XCTUnwrap(nsError.userInfo[NSUnderlyingErrorKey] as? NSError)
            XCTAssertEqual(underlying.domain, NSCocoaErrorDomain)
            XCTAssertEqual(underlying.code, CocoaError.fileReadUnknown.rawValue)
        }
    }
}
