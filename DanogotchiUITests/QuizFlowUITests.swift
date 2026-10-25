import XCTest

/// 학습하기 → 20문제 → 완료 화면 → 계속/끝내기, 그리고 중단 확인 알림
@MainActor
final class QuizFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_closeAsksConfirmationAndOnlyConfirmLeavesQuiz() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.startLearning"].tap()
        let progress = app.staticTexts["quiz.progressTitle"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.label, "1 / 20")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.choice.")).count, 4)

        app.buttons["quiz.close"].tap()
        let alert = app.alerts["학습 중단"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["취소"].tap()
        XCTAssertTrue(alert.waitForDisappearance())
        XCTAssertTrue(progress.exists)

        app.buttons["quiz.close"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["확인"].tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
        XCTAssertTrue(progress.waitForDisappearance())
    }

    func test_finishingQuizShowsResultAndContinueRestartsBeforeEnding() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.startLearning"].tap()
        answerAllQuestions(app)

        let title = app.staticTexts["completeQuiz.title"]
        XCTAssertEqual(title.label, "학습 완료!")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ / 20$")).firstMatch.exists)
        let primary = app.buttons["completeQuiz.primary"]
        XCTAssertEqual(primary.label, "계속 학습하기")
        // 보조 버튼은 오답 유무에 따라 다르지만, 보이는 "학습 끝내기"는 항상 하나다
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label == %@", "학습 끝내기")).count, 1)

        primary.tap()
        let progress = app.staticTexts["quiz.progressTitle"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.label, "1 / 20")
        answerAllQuestions(app)

        app.buttons.matching(NSPredicate(format: "label == %@", "학습 끝내기")).firstMatch.tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
        XCTAssertFalse(title.exists)
    }

    /// 첫 보기만 눌러 끝까지 간다 — 정답 여부는 결과 화면이 처리하므로 보지 않는다
    private func answerAllQuestions(_ app: XCUIApplication) {
        let progress = app.staticTexts["quiz.progressTitle"]
        let title = app.staticTexts["completeQuiz.title"]
        let choice = app.buttons["quiz.choice.0"]
        for _ in 0..<25 {
            if title.exists || !progress.exists { break }
            XCTAssertTrue(choice.waitForEnabled(true, timeout: 5))
            let before = progress.label
            choice.tap()
            // 1초 뒤 다음 문제로 넘어가거나, 마지막이면 완료 화면이 뜬다
            let moved = NSPredicate { _, _ in title.exists || (progress.exists && progress.label != before) }
            _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: moved, object: nil)], timeout: 5)
        }
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }
}
