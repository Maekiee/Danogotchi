import XCTest
@testable import Danogotchi

final class CrashContextTests: XCTestCase {
    func test_vocabCountBucketBoundaries() {
        let cases: [(Int, String)] = [
            (0, "0"), (1, "1-50"), (50, "1-50"), (51, "51-200"), (200, "51-200"), (201, "201+")
        ]
        for (count, bucket) in cases {
            XCTAssertEqual(CrashContext.vocabCountBucket(count), bucket, "\(count)")
        }
    }

    func test_petStageIsLevelNoneOrDead() {
        XCTAssertEqual(CrashContext.petStage(nil, now: testBase), "none")
        XCTAssertEqual(CrashContext.petStage(makePet(level: 3), now: testBase), "3")
        XCTAssertEqual(CrashContext.petStage(makePet(level: 7), now: testBase), "7")
        XCTAssertEqual(CrashContext.petStage(makePet(level: 3, hp: 0), now: testBase), "dead")
    }

    /// 저장된 HP가 남아 있어도 지금 기준으로 정산하면 죽은 펫은 dead다
    func test_petStageSettlesElapsedTimeWithoutSaving() {
        let neglected = makePet(level: 2, satiety: 0, hydration: 0, fun: 0, cleanliness: 0, hp: 1,
                                stateUpdatedAt: hoursAgo(1_000))

        XCTAssertEqual(CrashContext.petStage(neglected, now: testBase), "dead")
        XCTAssertEqual(neglected.hp, 1, "값 타입이라 원본은 바뀌지 않는다")
    }
}
