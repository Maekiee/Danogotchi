import XCTest

/// 돌보기·레벨 조작이 수치·기분·버튼 상태에 반영되는 흐름. 위치 권한은 거절해 날씨 배경은 기본값으로 둔다
@MainActor
final class CharacterUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_careRaisesStatChangesMoodAndDisablesFullStat() {
        let app = openCharacter()
        XCTAssertEqual(app.staticTexts["character.name"].label, "테스트")
        XCTAssertEqual(app.staticTexts["character.mood"].label, "만족함")
        XCTAssertEqual(app.element("character.experience").value as? String, "레벨 0, 0퍼센트")

        let satiety = app.element("character.stat.satiety")
        XCTAssertEqual(satiety.value as? String, "70퍼센트")
        let feed = app.buttons["character.care.satiety"]
        XCTAssertTrue(feed.isEnabled)
        feed.tap()
        XCTAssertTrue(satiety.waitForValue("95퍼센트"))
        // 80 이상이면 더 돌볼 수 없다
        XCTAssertTrue(feed.waitForEnabled(false))

        for stat in ["hydration", "fun", "cleanliness"] {
            app.buttons["character.care.\(stat)"].tap()
        }
        XCTAssertTrue(app.staticTexts["character.mood"].waitForLabel("행복함"))
        // 경험치 0이라 레벨업은 잠겨 있고, 살아 있어 부활 버튼은 숨어 있다
        XCTAssertFalse(app.buttons["character.levelUp"].isEnabled)
        XCTAssertFalse(app.buttons["character.revive"].exists)
    }

    func test_debugLevelButtonsMoveLevelAndCloseReturnsToExplore() {
        let app = openCharacter()
        let experience = app.element("character.experience")
        let plus = app.buttons["character.levelPlus"]
        app.scroll(to: plus)
        plus.tap()
        XCTAssertTrue(experience.waitForValue("레벨 1, 0퍼센트"))
        app.buttons["character.levelMinus"].tap()
        XCTAssertTrue(experience.waitForValue("레벨 0, 0퍼센트"))

        app.buttons["character.close"].tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
    }

    private func openCharacter() -> XCUIApplication {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.character"].tap()
        // 첫 진입에 위치 권한을 묻는다 — 거절해도 화면 흐름과 무관
        XCUIApplication.dismissSystemAlertIfNeeded()
        XCTAssertTrue(app.staticTexts["character.name"].waitForExistence(timeout: 5))
        return app
    }
}
