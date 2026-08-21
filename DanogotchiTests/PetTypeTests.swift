import XCTest
@testable import Danogotchi


final class PetTypeTests: XCTestCase {

    func test_시트_이름은_모든_레벨에서_번들의_실제_이미지로_로드된다() {
        for type in PetType.allCases {
            for level in 0...PetLevelPolicy.maxLevel {
                let name = type.sheetName(level: level)
                XCTAssertNotNil(UIImage(named: name), "\(name) 로드 실패")
            }
        }
    }

    func test_범위를_벗어난_레벨은_정책_상한으로_잘린다() {
        for type in PetType.allCases {
            XCTAssertEqual(type.sheetName(level: -1), type.sheetName(level: 0))
            XCTAssertEqual(
                type.sheetName(level: PetLevelPolicy.maxLevel + 1),
                type.sheetName(level: PetLevelPolicy.maxLevel)
            )
        }
    }
}
