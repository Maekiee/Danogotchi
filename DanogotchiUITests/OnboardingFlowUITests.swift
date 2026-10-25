import XCTest

/// 관심사 → 테마 → 알 → 이름 → 메인. 테마 검색은 네트워크라 그 화면 진입까지만 본다
@MainActor
final class OnboardingFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_interestSelectionEnablesNextAndOpensThemeSearch() {
        let app = XCUIApplication.launchFresh()
        XCTAssertTrue(app.staticTexts["관심 있는 주제를 골라주세요"].waitForExistence(timeout: 5))
        let next = app.buttons["interest.next"]
        XCTAssertFalse(next.isEnabled)

        app.element("interest.cell.travel").tap()
        XCTAssertTrue(next.waitForEnabled(true))
        // 다른 카드를 고르면 선택이 옮겨간다 — 선택 표시는 색이라 다음 버튼 상태만 본다
        app.element("interest.cell.life").tap()
        XCTAssertTrue(next.isEnabled)
        next.tap()

        XCTAssertTrue(app.staticTexts["배경 테마를 골라주세요"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["searchTheme.myPhoto"].exists)
        // 이미지를 고르기 전에는 시작 버튼이 숨어 있다
        XCTAssertFalse(app.buttons["searchTheme.submit"].isHittable)
        app.dismissNetworkAlertIfNeeded()
    }

    func test_eggAndNameScreensFinishOnboardingIntoMain() {
        // 테마까지 고른 상태라 알 선택이 첫 화면이다
        let app = XCUIApplication.launchFresh(seed: "-uiTestingThemeSelected")
        XCTAssertTrue(app.staticTexts["함께할 알을 골라주세요"].waitForExistence(timeout: 5))
        let next = app.buttons["egg.next"]
        XCTAssertFalse(next.isEnabled)

        app.element("egg.cell.1").tap()   // 준비중 칸은 선택되지 않는다
        XCTAssertFalse(next.isEnabled)
        app.element("egg.cell.0").tap()
        XCTAssertTrue(next.waitForEnabled(true))
        next.tap()

        XCTAssertTrue(app.staticTexts["이름을 지어주세요"].waitForExistence(timeout: 5))
        let field = app.textFields["petName.field"]
        let done = app.buttons["petName.done"]
        let error = app.staticTexts["petName.error"]
        XCTAssertFalse(done.isEnabled)

        field.tap()
        field.typeText("abcdefghijk")   // 11자 — 상한 초과
        XCTAssertTrue(error.waitForLabel("이름은 10자까지 지을 수 있어요"))
        XCTAssertFalse(done.isEnabled)

        field.typeText(XCUIKeyboardKey.delete.rawValue)   // 10자
        XCTAssertTrue(done.waitForEnabled(true))
        XCTAssertFalse(error.exists && !error.label.isEmpty)
        done.tap()

        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 10))
    }
}
