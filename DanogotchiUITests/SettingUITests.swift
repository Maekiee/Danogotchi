import XCTest

/// 설정 목록, 알림 토글 유지, 문의 안내, 테마 변경 화면 진입. 앱스토어·개인정보 링크는 앱 밖으로 나가므로 제외
@MainActor
final class SettingUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_reminderToggleSurvivesReopenAndMenusOpenTheirScreens() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.setting"].tap()
        let close = app.buttons["setting.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        for header in ["일반", "지원 및 피드백", "앱 정보"] {
            XCTAssertTrue(app.staticTexts[header].exists, header)
        }
        XCTAssertTrue(app.element("setting.menu.appVersion").exists)

        let toggle = app.switches["setting.reminderSwitch"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.tap()
        XCTAssertTrue(toggle.waitForValue("0"))

        // 닫고 다시 들어와도 꺼진 상태가 남는다
        close.tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
        app.buttons["explore.setting"].tap()
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")

        // 시뮬레이터에는 메일 계정이 없어 안내 알림이 뜬다
        app.element("setting.menu.inquiry").tap()
        let mailAlert = app.alerts["메일 전송 실패"]
        XCTAssertTrue(mailAlert.waitForExistence(timeout: 5))
        mailAlert.buttons["확인"].tap()
        XCTAssertTrue(mailAlert.waitForDisappearance())

        app.element("setting.menu.searchTheme").tap()
        XCTAssertTrue(app.staticTexts["배경 테마를 골라주세요"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["searchTheme.submit"].isHittable)
        app.dismissNetworkAlertIfNeeded()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
    }
}
