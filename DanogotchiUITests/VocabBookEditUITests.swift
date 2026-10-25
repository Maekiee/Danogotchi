import XCTest

/// 나의 단어장에서 단어 추가 → 수정 → 삭제가 목록에 반영되는 흐름
@MainActor
final class VocabBookEditUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_addEditAndDeleteWordInMyBook() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.library"].tap()
        let myBook = app.buttons["library.book.myBook"]
        XCTAssertTrue(myBook.waitForExistence(timeout: 5))
        myBook.tap()
        let emptyGuide = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "생성 및 추가해")).firstMatch
        XCTAssertTrue(emptyGuide.waitForExistence(timeout: 5))

        // 추가
        app.buttons["bookDetail.add"].tap()
        XCTAssertTrue(app.navigationBars["Add a word"].waitForExistence(timeout: 5))
        let save = app.buttons["addVocab.save"]
        XCTAssertFalse(save.isEnabled)
        let word = app.textFields["addVocab.word"]
        word.tap()
        word.typeText("apple")
        XCTAssertFalse(save.isEnabled)
        let meaning = app.textFields["addVocab.meaning"]
        meaning.tap()
        meaning.typeText("red fruit")
        app.segmentedControls["addVocab.partOfSpeech"].buttons["Noun"].tap()
        XCTAssertTrue(save.waitForEnabled(true))
        save.tap()
        // 저장 뒤 폼이 비워져 placeholder가 보이고 버튼이 다시 잠긴다
        XCTAssertTrue(word.waitForValue("단어"))
        XCTAssertTrue(save.waitForEnabled(false))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let cell = app.element("bookDetail.cell.apple")
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["red fruit"].exists)
        XCTAssertTrue(app.staticTexts["Noun"].exists)

        // 수정
        app.buttons["bookDetail.more.apple"].tap()
        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        sheet.buttons["수정하기"].tap()
        XCTAssertTrue(app.navigationBars["Edit a word"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["addVocab.word"].value as? String, "apple")
        let editing = app.textFields["addVocab.meaning"]
        XCTAssertEqual(editing.value as? String, "red fruit")
        // 글자가 짧아 가운데를 눌러도 커서는 문장 끝에 놓인다
        editing.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        editing.typeText(" (fruit)")
        app.buttons["addVocab.save"].tap()
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["red fruit (fruit)"].waitForExistence(timeout: 5))

        // 삭제
        app.buttons["bookDetail.more.apple"].tap()
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        sheet.buttons["지우기"].tap()
        XCTAssertTrue(cell.waitForDisappearance())
        XCTAssertTrue(emptyGuide.waitForExistence(timeout: 5))
    }
}
