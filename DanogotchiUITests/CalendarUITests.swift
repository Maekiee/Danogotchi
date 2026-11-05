import XCTest

// CALENDAR_UI_TEST 예시 기록: 기준 2026-11-03(화), 8/10 1개, 10/15 5개, 10/20 15개, 11/1 2개, 11/2 1개
@MainActor
final class CalendarUITests: XCTestCase {
    func test_opensOnTodayAndDateTapShowsDailyWordsAndDetail() {
        let app = launchCalendar()
        XCTAssertTrue(app.staticTexts["오늘은 아직 학습 기록이 없어요"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("calendar.month").label.contains("2026년 11월"))
        XCTAssertTrue(app.otherElements["연속 학습 2일"].exists)
        XCTAssertTrue(app.otherElements["총 학습일 5일"].exists)
        let heatmap = app.otherElements["최근 1년 학습 기록"]
        XCTAssertEqual(heatmap.value as? String, "5일 학습, 가장 많이 학습한 날 10월 20일 15개")
        XCTAssertFalse(app.buttons["다음 달"].isEnabled)
        XCTAssertFalse(app.buttons["오늘"].isEnabled)
        attachScreen(app, name: "calendar-today")

        app.buttons["이전 달"].tap()
        let day = app.buttons["10월 15일 목요일, 학습 단어 5개"]
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["오늘"].isEnabled)
        day.tap()
        XCTAssertTrue(app.staticTexts["10월 15일 (목)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["단어 5개 · 정답률 60% · 퀴즈 1회"].exists)
        attachScreen(app, name: "calendar-selected-day")

        let journey = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "journey")).firstMatch
        app.scroll(to: journey)
        journey.tap()
        let card = app.element("calendar.detailCard")
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        for text in ["journey", "여행", "명사", "이날 정답 2 / 2회", "100%"] {
            XCTAssertTrue(card.label.contains(text), "단어 카드에서 \(text) 누락: \(card.label)")
        }
        attachScreen(app, name: "calendar-word-detail")
    }

    func test_monthMenuStopsAtEarliestMonthAndShowsEmptyMonth() {
        let app = launchCalendar()
        let menu = app.element("calendar.month")
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["2026년 9월"].tap()
        XCTAssertTrue(app.staticTexts["이 달에는 학습 기록이 없어요"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["오늘은 아직 학습 기록이 없어요"].exists)
        app.buttons["이전 달"].tap()
        XCTAssertTrue(menu.waitForLabel("2026년 8월") || menu.label.contains("2026년 8월"))
        XCTAssertTrue(app.buttons["이전 달"].waitForEnabled(false))
        app.buttons["오늘"].tap()
        XCTAssertTrue(app.staticTexts["오늘은 아직 학습 기록이 없어요"].waitForExistence(timeout: 5))
    }

    func test_emptyStateKeepsStatsButton() {
        let app = launchCalendar(scenario: "empty")
        XCTAssertTrue(app.staticTexts["학습을 시작하면 잔디와 달력이 채워져요"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["연속 학습 0일"].exists)
        XCTAssertFalse(app.buttons["오늘"].isEnabled)
        XCTAssertFalse(app.buttons["이전 달"].isEnabled)
        XCTAssertFalse(app.staticTexts["날짜를 누르면 그날 학습한 단어를 볼 수 있어요"].exists)
        attachScreen(app, name: "calendar-empty")
        app.buttons["calendar.stats"].tap()
        XCTAssertTrue(app.navigationBars["학습 통계"].waitForExistence(timeout: 10))
    }

    func test_failureShowsRetryAndKeepsStatsButton() {
        let app = launchCalendar(scenario: "error")
        let retry = app.buttons["다시 시도"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["최근 1년 학습 기록"].exists)
        attachScreen(app, name: "calendar-error")
        retry.tap()
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        app.buttons["calendar.stats"].tap()
        XCTAssertTrue(app.navigationBars["학습 통계"].waitForExistence(timeout: 10))
    }

    // 탐색 화면의 차트 아이콘으로 고정 기록 캘린더 진입
    private func launchCalendar(scenario: String = "normal") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset", "-uiTestingMainFlow", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment["CALENDAR_UI_TEST"] = scenario
        app.launch()
        XCUIApplication.dismissSystemAlertIfNeeded()
        XCTAssertTrue(app.buttons["explore.studyStats"].waitForExistence(timeout: 10))
        app.buttons["explore.studyStats"].tap()
        XCTAssertTrue(app.navigationBars["캘린더"].waitForExistence(timeout: 10))
        return app
    }

    private func attachScreen(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
