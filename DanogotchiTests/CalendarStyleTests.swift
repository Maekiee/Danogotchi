import SwiftUI
import XCTest
@testable import Danogotchi

final class CalendarStyleTests: XCTestCase {
    func test_percentValueRoundsAndIsZeroWithoutAnswers() {
        XCTAssertEqual(CalendarStyle.percentValue(0, 0), 0)
        XCTAssertEqual(CalendarStyle.percentValue(1, 3), 33)
        XCTAssertEqual(CalendarStyle.percentValue(2, 3), 67)
        XCTAssertEqual(CalendarStyle.percentValue(3, 3), 100)
    }

    func test_partTitleNamesEachPartOfSpeechAndFallsBackToUnknown() {
        let expected = ["noun": "명사", "verb": "동사", "adj": "형용사", "adv": "부사"]
        for (id, title) in expected {
            XCTAssertEqual(CalendarStyle.partTitle(id), String(localized: String.LocalizationValue(title)), id)
        }
        for id in ["unknown", "", nil] {
            XCTAssertEqual(CalendarStyle.partTitle(id), String(localized: "미분류"), String(describing: id))
        }
    }

    func test_levelColorGetsDarkerPerLevelAndClampsOutOfRange() {
        let colors = (0...4).map(CalendarStyle.levelColor)
        XCTAssertEqual(Set(colors).count, 5)
        XCTAssertEqual(CalendarStyle.levelColor(-1), colors[0])
        XCTAssertEqual(CalendarStyle.levelColor(9), colors[4])
    }
}
