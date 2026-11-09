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

    func test_monthSheetPicksPastMonthAndStopsAtOldestYear() {
        let app = launchCalendar()
        let month = app.element("calendar.month")
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        month.tap()
        XCTAssertTrue(app.staticTexts["월 선택"].waitForExistence(timeout: 5))
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "9월")
        attachScreen(app, name: "calendar-month-sheet")
        app.buttons["선택한 월 보기"].tap()
        XCTAssertTrue(app.staticTexts["이 달에는 학습 기록이 없어요"].waitForExistence(timeout: 5))
        XCTAssertTrue(month.label.contains("2026년 9월"))

        // 연도 휠은 현재 연도 포함 5개(2022~2026), 가장 이른 달에서는 ‹ 비활성
        month.tap()
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "2022")
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "1월")
        app.buttons["선택한 월 보기"].tap()
        XCTAssertTrue(month.waitForLabel("2022년 1월") || month.label.contains("2022년 1월"))
        XCTAssertTrue(app.buttons["이전 달"].waitForEnabled(false))

        // 취소는 달을 바꾸지 않는다
        month.tap()
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "2025")
        app.buttons["취소"].tap()
        XCTAssertTrue(app.staticTexts["월 선택"].waitForDisappearance())
        XCTAssertTrue(month.label.contains("2022년 1월"))
        app.buttons["오늘"].tap()
        XCTAssertTrue(app.staticTexts["오늘은 아직 학습 기록이 없어요"].waitForExistence(timeout: 5))
    }

    func test_swipeMovesMonthButNotIntoFuture() {
        let app = launchCalendar()
        let month = app.element("calendar.month")
        let november = app.buttons["11월 2일 월요일, 학습 단어 1개"]
        XCTAssertTrue(november.waitForExistence(timeout: 5))
        drag(november, by: 160)
        XCTAssertTrue(app.buttons["10월 15일 목요일, 학습 단어 5개"].waitForExistence(timeout: 5))
        XCTAssertTrue(month.label.contains("2026년 10월"))
        drag(app.buttons["10월 15일 목요일, 학습 단어 5개"], by: -160)
        XCTAssertTrue(november.waitForExistence(timeout: 5))
        // 화면 밖으로 끌지 않도록 가운데 열(오늘)에서 시작
        drag(app.buttons["11월 3일 화요일, 학습 안 함"], by: -160)
        XCTAssertTrue(month.label.contains("2026년 11월"))
        XCTAssertFalse(app.buttons["다음 달"].isEnabled)
    }

    func test_emptyStateKeepsStatsButtonAndMovesToPastMonths() {
        let app = launchCalendar(scenario: "empty")
        XCTAssertTrue(app.staticTexts["학습을 시작하면 잔디와 달력이 채워져요"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["연속 학습 0일"].exists)
        XCTAssertFalse(app.buttons["오늘"].isEnabled)
        XCTAssertFalse(app.staticTexts["날짜를 누르면 그날 학습한 단어를 볼 수 있어요"].exists)
        attachScreen(app, name: "calendar-empty")

        // 기록이 없어도 과거 달로 이동하고 오늘로 돌아온다
        app.buttons["이전 달"].tap()
        XCTAssertTrue(app.element("calendar.month").label.contains("2026년 10월"))
        XCTAssertTrue(app.buttons["오늘"].waitForEnabled(true))
        app.buttons["오늘"].tap()
        XCTAssertTrue(app.element("calendar.month").label.contains("2026년 11월"))

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

    // 셀이 작아 swipeLeft/Right 거리가 짧을 수 있어 좌표로 가로 드래그
    private func drag(_ element: XCUIElement, by offset: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: offset, dy: 0)))
    }

    private func attachScreen(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
