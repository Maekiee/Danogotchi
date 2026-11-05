import XCTest

@MainActor
final class StudyStatsUITests: XCTestCase {
    func test_mistakeThresholdFiltersRowsAndShowsEmptyGuidance() {
        let app = launchStats()
        let first = app.buttons["studyStats.mistake.1"]
        scrollTo(first, in: app)
        for text in ["prepare", "오답 3회", "준비하다", "정답률 25%", "전체 4회 풀이"] {
            XCTAssertTrue(first.label.contains(text), "첫 행에서 \(text) 누락: \(first.label)")
        }
        // 오답 횟수가 같으면 정답률이 낮은 단어가 위
        for (rank, word) in [(2, "happily"), (3, "moment")] {
            let row = app.buttons["studyStats.mistake.\(rank)"]
            scrollTo(row, in: app)
            XCTAssertTrue(row.label.hasPrefix(word), "\(rank)번째 행: \(row.label)")
        }
        XCTAssertFalse(app.buttons["studyStats.mistake.4"].exists)
        XCTAssertTrue(app.staticTexts["정답률 70% 이하 · 3개"].exists)
        attachScreen(app, name: "mistakes-70")

        let picker = app.segmentedControls["studyStats.mistakeThreshold"]
        scrollBackTo(picker, in: app)
        picker.buttons["40% 이하"].tap()
        XCTAssertTrue(app.staticTexts["정답률 40% 이하 · 1개"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["studyStats.mistake.1"].label.hasPrefix("prepare"))
        XCTAssertFalse(app.buttons["studyStats.mistake.2"].exists)

        picker.buttons["20% 이하"].tap()
        XCTAssertTrue(app.staticTexts["정답률 20% 이하인 단어가 없어요"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["정답률 20% 이하 · 0개"].exists)
        XCTAssertFalse(app.buttons["studyStats.mistake.1"].exists)
        attachScreen(app, name: "mistakes-20-empty")
    }

    func test_mistakeRowOpensDetailSheetWithLifetimeCounts() {
        let app = launchStats()
        let first = app.buttons["studyStats.mistake.1"]
        scrollTo(first, in: app)
        first.tap()
        assertDetail(in: app, texts: ["prepare", "준비하다", "동사", "25%", "정답 1 / 4회"])
        attachScreen(app, name: "word-detail-sheet")
        dismissDetail(in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
    }

    func test_allWordsListKeepsSubtitleAndOpensSameDetailCard() {
        let app = launchStats()
        let allWords = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "누적 학습 단어")).firstMatch
        XCTAssertTrue(allWords.waitForExistence(timeout: 5))
        XCTAssertTrue(allWords.label.contains("5개"))
        allWords.tap()
        XCTAssertTrue(app.navigationBars["학습한 단어"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["전체 학습 단어"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "중복 제외 5개")).firstMatch.exists)
        let journey = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "journey")).firstMatch
        XCTAssertTrue(journey.exists)
        journey.tap()
        assertDetail(in: app, texts: ["journey", "여행", "명사", "78%", "정답 267 / 342회"])
        dismissDetail(in: app)
        XCTAssertTrue(app.navigationBars["학습한 단어"].waitForExistence(timeout: 5))
    }

    func test_topicSelectionStaysAfterTouchEndsAndLegendSelects() {
        let app = launchStats()
        dismissNotificationPermissionIfNeeded()
        // 다음 카드 제목이 보이면 주제 카드 전체가 화면 안에 있음
        scrollTo(app.staticTexts["학습 단어의 품사"], in: app)
        press(chartMark("여행", value: "342회, 96%", in: app))
        XCTAssertTrue(app.staticTexts["여행 · 342회 · 전체의 96%"].waitForExistence(timeout: 3))
        let business = app.buttons["studyStats.topics.business"]
        business.tap()
        XCTAssertTrue(app.staticTexts["비즈니스 · 5회 · 전체의 1%"].waitForExistence(timeout: 3))
        XCTAssertTrue(business.isSelected)
        // 0회 주제도 범례에 남음
        XCTAssertTrue(app.buttons["studyStats.topics.emotion"].label.contains("0회"))
        attachScreen(app, name: "topic-selection")
    }

    func test_partSelectionStaysAfterTouchEnds() {
        let app = launchStats()
        dismissNotificationPermissionIfNeeded()
        scrollTo(app.staticTexts["많이 틀린 단어"], in: app)
        press(chartMark("명사", value: "2개, 40%", in: app))
        XCTAssertTrue(app.staticTexts["명사 · 2개 · 전체의 40%"].waitForExistence(timeout: 3))
        attachScreen(app, name: "part-selection")
    }

    func test_emptyStatsShowsOnlyEmptyGuidance() {
        let app = launchStats(scenario: "empty")
        XCTAssertTrue(app.staticTexts["첫 학습을 기다리고 있어요"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["많이 틀린 단어"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "누적 학습 단어")).firstMatch.exists)
    }

    func test_failedStatsKeepsRetryControl() {
        let app = launchStats(scenario: "error")
        XCTAssertTrue(app.buttons["다시 시도"].waitForExistence(timeout: 5))
        app.buttons["다시 시도"].tap()
        XCTAssertTrue(app.buttons["다시 시도"].waitForExistence(timeout: 5))
    }

    private func launchStats(scenario: String = "normal") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launchEnvironment["STUDY_STATS_UI_TEST"] = scenario
        app.launch()
        // 진입 화면은 캘린더, 학습 통계는 push로 연다
        XCTAssertTrue(app.navigationBars["캘린더"].waitForExistence(timeout: 10))
        app.buttons["calendar.stats"].tap()
        XCTAssertTrue(app.navigationBars["학습 통계"].waitForExistence(timeout: 10))
        return app
    }

    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<14 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func assertDetail(in app: XCUIApplication, texts: [String]) {
        let card = app.descendants(matching: .any).matching(identifier: "studyStats.detailCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        for text in texts {
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

    // 알림 권한 팝업의 dim·터치 가로채기 방지
    private func dismissNotificationPermissionIfNeeded() {
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if permission.waitForExistence(timeout: 3) { permission.buttons.element(boundBy: 0).tap() }
    }

    private func chartMark(_ label: String, value: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ AND value == %@", label, value))
            .firstMatch
    }

    // 짧은 탭은 스크롤 뷰 안 차트 선택 제스처로 인식되지 않아 길게 누른 뒤 뗌
    private func press(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.5)
    }

    private func dismissDetail(in app: XCUIApplication) {
        let sheet = app.scrollViews["studyStats.wordDetail"]
        sheet.swipeDown()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
    }
}
