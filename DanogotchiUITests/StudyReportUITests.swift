import UIKit
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

    func test_activityChartShowsBarForStudiedDay() {
        let app = launchReport()
        dismissNotificationPermissionIfNeeded()
        let selection = app.staticTexts["9월 29일 · 학습한 단어 5개"]
        scrollTo(selection, in: app)
        let bar = chartMark("2026년 9월 29일", value: "학습 단어 5개", in: app)
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        attachScreen(app, name: "activity-chart")
        // 접근성 frame은 막대 폭이 0이어도 잡히므로 실제 막대 색 픽셀로 판정
        XCTAssertTrue(containsBarColor(bar.screenshot().image), "막대가 화면에 그려지지 않음: \(bar.frame)")
    }

    func test_activitySelectionStaysAfterTouchEnds() {
        let app = launchReport()
        dismissNotificationPermissionIfNeeded()
        scrollTo(app.staticTexts["9월 29일 · 학습한 단어 5개"], in: app)
        press(chartMark("2026년 9월 27일", value: "학습 단어 0개", in: app))
        XCTAssertTrue(app.staticTexts["9월 27일 · 학습한 단어 0개"].waitForExistence(timeout: 3))
        attachScreen(app, name: "activity-selection")
    }

    func test_sessionSelectionStaysAfterTouchEnds() {
        let app = launchReport()
        dismissNotificationPermissionIfNeeded()
        scrollTo(app.staticTexts["9.29 11:59 · 정답 0 / 1문제 · 0%"], in: app)
        // 선 차트의 점은 개별 접근성 요소가 없어 플롯 좌표로 누름 (회차 2개 중 첫 회차 = 왼쪽 1/4 지점)
        press(app.otherElements["studyReport.sessionChart"].firstMatch, dx: 0.25)
        XCTAssertTrue(app.staticTexts["9.29 11:54 · 정답 1 / 1문제 · 100%"].waitForExistence(timeout: 3))
        attachScreen(app, name: "session-selection")
    }

    func test_partSelectionStaysAfterTouchEnds() {
        let app = launchReport()
        dismissNotificationPermissionIfNeeded()
        // 다음 카드 제목이 보이면 품사 카드 전체가 화면 안에 있음
        scrollTo(app.staticTexts["많이 틀린 종류"], in: app)
        press(chartMark("명사", value: "2개, 40%", in: app))
        XCTAssertTrue(app.staticTexts["명사 · 2 / 5개 · 40%"].waitForExistence(timeout: 3))
        attachScreen(app, name: "part-selection")
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
    private func press(_ element: XCUIElement, dx: CGFloat = 0.5) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: 0.5)).press(forDuration: 0.5)
    }

    // 막대 색(coral) 계열 픽셀 존재 여부 — 흰 카드·회색 축은 R과 B 차이가 거의 없음
    private func containsBarColor(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?
                .draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return stride(from: 0, to: pixels.count, by: 4).contains { Int(pixels[$0]) - Int(pixels[$0 + 2]) > 40 }
    }

    private func dismissDetail(in app: XCUIApplication) {
        let sheet = app.scrollViews["studyReport.wordDetail"]
        sheet.swipeDown()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
    }
}
