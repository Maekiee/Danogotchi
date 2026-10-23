import XCTest

/// 탐색 화면의 진입 버튼들 — 학습 리포트 열기/닫기, 발음 버튼
@MainActor
final class ExploreNavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_studyReportOpensFromExploreAndCloseReturns() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.studyReport"].tap()
        XCTAssertTrue(app.navigationBars["학습 리포트"].waitForExistence(timeout: 10))
        // 학습 기록이 없는 첫 설치 상태
        XCTAssertTrue(app.staticTexts["첫 학습을 기다리고 있어요"].waitForExistence(timeout: 5))

        app.buttons["학습 리포트 닫기"].tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["학습 리포트"].exists)
    }

    func test_speakButtonOnVisibleCardIsTappable() throws {
        let app = XCUIApplication.launchMainFlow()
        let speak = try XCTUnwrap(
            app.buttons.matching(identifier: "explore.speak").allElementsBoundByIndex.first { $0.isHittable }
        )
        XCTAssertEqual(speak.value as? String, "대기")
        speak.tap()
        // 발음 길이는 TTS에 달려 있어 "발음 중" 또는 이미 끝난 "대기" 둘 중 하나다
        XCTAssertTrue(["발음 중", "대기"].contains(speak.value as? String ?? ""), String(describing: speak.value))
    }
}
