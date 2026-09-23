import XCTest

/// 온보딩 테마 화면 → 내 사진 모달 흐름. 사진첩은 별도 프로세스라 열림·취소까지만 조작한다.
@MainActor
final class PhotoThemeOnboardingUITests: XCTestCase {
    private let photoTitle = "내 사진으로 지정"
    private let closeIdentifier = "photoTheme.close"

    func test_myPhotoOpensModalAndAutoPresentsPickerOnce() {
        let app = launchToSearchTheme()
        app.buttons[photoTitle].tap()

        // 모달 전환이 끝난 뒤 사진첩이 자동으로 떠야 한다
        dismissPicker(in: app)
        XCTAssertTrue(app.navigationBars[photoTitle].exists)
        XCTAssertTrue(app.staticTexts["배경으로 쓸 사진을 골라주세요"].exists)
        XCTAssertFalse(app.buttons["이미지 테마로 지정"].isEnabled)

        // 취소 후 다시 나타나도 자동으로 열지 않는다
        Thread.sleep(forTimeInterval: 2)
        XCTAssertFalse(pickerDismissButton(in: app).exists)
    }

    func test_closeReturnsToSearchTheme() {
        let app = launchToSearchTheme()
        app.buttons[photoTitle].tap()
        dismissPicker(in: app)

        app.buttons[closeIdentifier].tap()

        XCTAssertTrue(waitForDisappearance(of: app.navigationBars[photoTitle]))
        XCTAssertTrue(app.buttons[photoTitle].isHittable)
    }

    func test_pickerButtonReopensPicker() {
        let app = launchToSearchTheme()
        app.buttons[photoTitle].tap()
        dismissPicker(in: app)

        app.buttons["사진첩에서 사진 고르기"].tap()

        dismissPicker(in: app)
        XCTAssertTrue(app.navigationBars[photoTitle].exists)
    }

    // MARK: - Helpers

    /// 첫 설치 상태로 실행해 관심사 선택을 지나 테마 검색 화면까지 간다
    private func launchToSearchTheme() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        // 시스템 버튼 문구(취소·닫기)를 한국어로 고정
        app.launchArguments = ["-uiTestingReset", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        dismissNotificationPermissionIfNeeded()

        let firstTopic = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstTopic.waitForExistence(timeout: 5))
        firstTopic.tap()
        app.buttons["다음"].tap()

        XCTAssertTrue(app.buttons[photoTitle].waitForExistence(timeout: 5))
        // 오프라인이면 테마 검색 실패 알림이 뜬다 — 이 흐름과 무관하므로 닫는다
        let networkAlert = app.alerts["알림"]
        if networkAlert.waitForExistence(timeout: 2) {
            networkAlert.buttons["확인"].tap()
        }
        return app
    }

    /// 알림 권한은 시뮬레이터에 한 번 결정되면 다시 묻지 않는다
    private func dismissNotificationPermissionIfNeeded() {
        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            // 첫 버튼이 "허용 안 함" — 기기 언어와 무관하게 순서로 고른다
            alert.buttons.element(boundBy: 0).tap()
        }
    }

    /// iOS 버전에 따라 사진첩 버튼이 "취소"이거나 X("닫기")다 — 모달의 닫기 버튼은 제외
    private func pickerDismissButton(in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "label IN %@ AND identifier != %@",
                                    ["취소", "닫기", "Cancel", "Close"], closeIdentifier)
        return app.buttons.matching(predicate).firstMatch
    }

    private func dismissPicker(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = pickerDismissButton(in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5), "사진첩이 열리지 않았다", file: file, line: line)
        button.tap()
        XCTAssertTrue(waitForDisappearance(of: button), file: file, line: line)
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }
}
