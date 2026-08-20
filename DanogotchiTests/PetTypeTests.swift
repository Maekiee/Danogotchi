import XCTest
@testable import Danogotchi


final class PetTypeTests: XCTestCase {

    func test_pet_에셋_이름은_번들에서_실제_이미지로_로드된다() {
        for type in PetType.allCases {
            XCTAssertNotNil(UIImage(named: type.imageName), "\(type.imageName) 로드 실패")
        }
    }
}
