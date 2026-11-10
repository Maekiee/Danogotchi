import XCTest
@testable import Danogotchi

final class StudyStatsStyleTests: XCTestCase {
    private let unknown = String(localized: "미분류")

    func test_topicTitleNamesEachRecommendedBook() {
        let expected = ["travel": "여행", "business": "비즈니스", "emotion": "감정", "life": "일상"]
        for (id, title) in expected {
            XCTAssertEqual(StudyStatsStyle.topicTitle(id), String(localized: String.LocalizationValue(title)), id)
        }
    }

    // 나의 단어장은 주제 통계에서 미분류로 묶인다
    func test_topicTitleFallsBackToUnknownForMyBookAndUnknownValues() {
        for id in ["myBook", "unknown", "new-topic", "", nil] {
            XCTAssertEqual(StudyStatsStyle.topicTitle(id), unknown, String(describing: id))
        }
    }

    func test_partTitleNamesEachPartOfSpeech() {
        let expected = ["noun": "명사", "verb": "동사", "adj": "형용사", "adv": "부사"]
        for (id, title) in expected {
            XCTAssertEqual(StudyStatsStyle.partTitle(id), String(localized: String.LocalizationValue(title)), id)
        }
    }

    func test_partTitleFallsBackToUnknown() {
        for id in ["unknown", "new-part", "", nil] {
            XCTAssertEqual(StudyStatsStyle.partTitle(id), unknown, String(describing: id))
        }
    }

    func test_percentRoundsAndShowsDashWithoutAnswers() {
        XCTAssertEqual(StudyStatsStyle.percent(0, 0), "—")
        XCTAssertEqual(StudyStatsStyle.percent(0, 3), "0%")
        XCTAssertEqual(StudyStatsStyle.percent(1, 3), "33%")
        XCTAssertEqual(StudyStatsStyle.percent(2, 3), "67%")
        XCTAssertEqual(StudyStatsStyle.percent(3, 3), "100%")
    }
}
