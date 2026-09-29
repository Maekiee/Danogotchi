import XCTest

@MainActor
final class StudyReportUITests: XCTestCase {
    func test_mistakesHideEmptySummaryAndKeepCountsAndSelection() {
        let app = launchReport()
        let travel = app.buttons["studyReport.mistakes.travel"]
        scrollTo(travel, in: app)
        XCTAssertTrue(travel.label.contains("전체 342회"))
        XCTAssertTrue(travel.label.contains("22%"))
        XCTAssertTrue(travel.label.contains("정답 267회, 오답 75회"))

        let empty = app.buttons["studyReport.mistakes.emotion"]
        scrollTo(empty, in: app)
        XCTAssertFalse(empty.label.contains("전체 0회"))
        XCTAssertFalse(empty.label.contains("오답률"))
        XCTAssertFalse(empty.label.contains("0 정답"))
        empty.tap()
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "감정 · 오답 0")).firstMatch.exists)
        attachScreen(app, name: "mistakes-zero-and-counts")

        let picker = app.segmentedControls["studyReport.mistakeKind"]
        scrollBackTo(picker, in: app)
        picker.buttons["품사"].tap()
        XCTAssertTrue(app.buttons["studyReport.mistakes.noun"].waitForExistence(timeout: 5))
    }

    func test_ranksAndDetailSheetDismissal() {
        let app = launchReport()
        for rank in 1...5 {
            let row = app.buttons["studyReport.rank.\(rank)"]
            scrollTo(row, in: app)
            XCTAssertNotNil(row.label.range(of: "^\(rank)\\b", options: .regularExpression))
        }
        let first = app.buttons["studyReport.rank.1"]
        scrollBackTo(first, in: app)
        first.tap()
        assertDetail(in: app)
        attachScreen(app, name: "word-detail-sheet")
        dismissDetail(in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
    }

    func test_allWordsListKeepsSubtitleAndOpensSameDetailCard() {
        let app = launchReport()
        let allWords = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "누적 학습 단어")).firstMatch
        XCTAssertTrue(allWords.waitForExistence(timeout: 5))
        allWords.tap()
        XCTAssertTrue(app.navigationBars["학습한 단어"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["전체 학습 단어"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "중복 제외 5개")).firstMatch.exists)
        let journey = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "journey")).firstMatch
        XCTAssertTrue(journey.exists)
        journey.tap()
        assertDetail(in: app)
        dismissDetail(in: app)
        XCTAssertTrue(app.navigationBars["학습한 단어"].waitForExistence(timeout: 5))
    }

    func test_emptyReportKeepsEmptyGuidance() {
        let app = launchReport(scenario: "empty")
        XCTAssertTrue(app.staticTexts["첫 학습을 기다리고 있어요"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["많이 틀린 종류"].exists)
    }

    func test_failedReportKeepsRetryControl() {
        let app = launchReport(scenario: "error")
        XCTAssertTrue(app.buttons["다시 시도"].waitForExistence(timeout: 5))
        app.buttons["다시 시도"].tap()
        XCTAssertTrue(app.buttons["다시 시도"].waitForExistence(timeout: 5))
    }

    private func launchReport(scenario: String = "normal") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment["STUDY_REPORT_UI_TEST"] = scenario
        app.launch()
        XCTAssertTrue(app.navigationBars["학습 리포트"].waitForExistence(timeout: 10))
        return app
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<14 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func assertDetail(in app: XCUIApplication) {
        let card = app.descendants(matching: .any).matching(identifier: "studyReport.detailCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        for text in ["journey", "여행", "명사", "78%", "정답 267 / 342회"] {
            XCTAssertTrue(card.label.contains(text), "단어 카드에서 \(text) 누락: \(card.label)")
        }
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "주제 ·")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "최근 학습 ·")).firstMatch.exists)
        XCTAssertFalse(app.buttons["닫기"].exists)
    }

    private func scrollBackTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<14 {
            if element.isHittable { return }
            app.swipeDown()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func attachScreen(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func dismissDetail(in app: XCUIApplication) {
        let sheet = app.scrollViews["studyReport.wordDetail"]
        sheet.swipeDown()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
    }
}
