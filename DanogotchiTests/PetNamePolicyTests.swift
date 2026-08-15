import XCTest
@testable import Danogotchi


final class PetNamePolicyTests: XCTestCase {

    func test_앞뒤_공백과_줄바꿈을_제거한다() {
        XCTAssertEqual(PetNamePolicy.validate("  새싹이  "), .valid("새싹이"))
        XCTAssertEqual(PetNamePolicy.validate("\n새싹이\n"), .valid("새싹이"))
        XCTAssertEqual(PetNamePolicy.validate("\t 새싹이 \n"), .valid("새싹이"))
    }

    func test_빈_값과_공백만_있는_이름은_안내_없이_비활성이다() {
        XCTAssertEqual(PetNamePolicy.validate(""), .empty)
        XCTAssertEqual(PetNamePolicy.validate("   "), .empty)
        XCTAssertEqual(PetNamePolicy.validate("\n\t "), .empty)
    }

    func test_한_자는_통과한다() {
        XCTAssertEqual(PetNamePolicy.validate("싹"), .valid("싹"))
    }

    func test_상한_경계에서_10자는_통과하고_11자는_초과로_판정한다() {
        let ten = String(repeating: "가", count: PetNamePolicy.maxLength)
        let eleven = ten + "가"

        XCTAssertEqual(PetNamePolicy.validate(ten), .valid(ten))
        XCTAssertEqual(PetNamePolicy.validate(eleven), .tooLong(11))
    }

    func test_공백을_제거한_뒤_길이를_재므로_앞뒤_공백은_상한에_포함되지_않는다() {
        let ten = String(repeating: "가", count: PetNamePolicy.maxLength)

        XCTAssertEqual(PetNamePolicy.validate("  \(ten)  "), .valid(ten))
    }

    func test_중간_공백은_지우지_않고_길이에_포함한다() {
        XCTAssertEqual(PetNamePolicy.validate(" 새싹 이 "), .valid("새싹 이"))
        // 9글자 + 공백 2개 = 11자라 상한을 넘는다
        XCTAssertEqual(PetNamePolicy.validate("가 나 다라마바사아자"), .tooLong(11))
    }

    func test_이모지와_한글_조합_문자를_한_자로_센다() {
        let emojis = String(repeating: "🐣", count: PetNamePolicy.maxLength)

        XCTAssertEqual(PetNamePolicy.validate(emojis), .valid(emojis))
        XCTAssertEqual(PetNamePolicy.validate(emojis + "🐣"), .tooLong(11))
        XCTAssertEqual(PetNamePolicy.validate("👩‍👩‍👧‍👦"), .valid("👩‍👩‍👧‍👦"))
    }
}
