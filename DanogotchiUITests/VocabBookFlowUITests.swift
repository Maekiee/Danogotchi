import XCTest

/// 단어 저장·학습 단어장 지정이 탐색·라이브러리·상세 화면에 반영되는 흐름
@MainActor
final class VocabBookFlowUITests: XCTestCase {
    private let saved = "저장됨"
    private let unsaved = "저장 안 됨"
    private let learning = "학습중"

    func test_saveToggleReflectsInMyBook() throws {
        let app = launchToExplore()
        let word = try visibleWord(in: app)
        let save = saveButton(for: word, in: app)
        XCTAssertEqual(save.value as? String, unsaved)

        save.tap()
        XCTAssertTrue(save.waitForValue(saved))

        // 저장한 단어가 나의 단어장에 담긴다
        openMyBook(in: app)
        XCTAssertTrue(app.staticTexts[word].waitForExistence(timeout: 5))
        goBack(in: app)
        app.buttons["library.close"].tap()

        // 해제하면 나의 단어장이 다시 빈다
        XCTAssertTrue(save.waitForValue(saved))
        save.tap()
        XCTAssertTrue(save.waitForValue(unsaved))
        openMyBook(in: app)
        let emptyGuide = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "생성 및 추가해")).firstMatch
        XCTAssertTrue(emptyGuide.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts[word].exists)
    }

    func test_startLearningRefreshesLibraryAndExplore() throws {
        let app = launchToExplore()
        let word = try visibleWord(in: app)
        let save = saveButton(for: word, in: app)
        save.tap()
        XCTAssertTrue(save.waitForValue(saved))

        app.buttons["explore.library"].tap()
        let travel = app.buttons["library.book.travel"]
        let myBook = app.buttons["library.book.myBook"]
        XCTAssertTrue(travel.waitForValue(learning))
        XCTAssertNotEqual(myBook.value as? String, learning)

        // 나의 단어장을 학습 단어장으로 지정한다
        myBook.tap()
        let start = app.navigationBars.buttons["학습하기"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(app.navigationBars.buttons[learning].waitForExistence(timeout: 5))

        // 라이브러리의 학습중 표시가 옮겨간다
        goBack(in: app)
        XCTAssertTrue(myBook.waitForValue(learning))
        XCTAssertNotEqual(travel.value as? String, learning)

        // 탐색 화면이 나의 단어장으로 바뀌어 저장 버튼이 사라진다
        app.buttons["library.close"].tap()
        XCTAssertTrue(app.staticTexts[word].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(identifier: "explore.save").firstMatch.waitForDisappearance())
    }

    // MARK: - Helpers

    /// 첫 설치 상태에서 온보딩을 건너뛰고 여행 단어장을 학습 중인 탐색 화면으로 실행한다
    private func launchToExplore() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingReset", "-uiTestingMainFlow", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        XCUIApplication.dismissSystemAlertIfNeeded()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 10))
        return app
    }

    /// 루프용 복제 카드가 있어 화면에 보이는 저장 버튼의 단어를 고른다
    private func visibleWord(in app: XCUIApplication) throws -> String {
        let buttons = app.buttons.matching(identifier: "explore.save")
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 5))
        let visible = try XCTUnwrap(buttons.allElementsBoundByIndex.first { $0.isHittable })
        return String(visible.label.dropLast(" 저장".count))
    }

    private func saveButton(for word: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ AND label == %@", "explore.save", "\(word) 저장")
        return app.buttons.matching(predicate).firstMatch
    }

    private func openMyBook(in app: XCUIApplication) {
        app.buttons["explore.library"].tap()
        let myBook = app.buttons["library.book.myBook"]
        XCTAssertTrue(myBook.waitForExistence(timeout: 5))
        myBook.tap()
        XCTAssertTrue(app.navigationBars.buttons["학습하기"].waitForExistence(timeout: 5))
    }

    /// 상세 화면의 뒤로 버튼은 제목 없이 표시된다
    private func goBack(in app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["library.close"].waitForExistence(timeout: 5))
    }
}
