import XCTest
@testable import Danogotchi


final class PetLevelPolicyTests: XCTestCase {

    func test_레벨별_요구_경험치는_100씩_늘어난다() {
        XCTAssertEqual(PetLevelPolicy.requiredExperience(level: 0), 100)
        XCTAssertEqual(PetLevelPolicy.requiredExperience(level: 1), 200)
        XCTAssertEqual(PetLevelPolicy.requiredExperience(level: 2), 300)
    }

    func test_레벨_시작_누적_경험치() {
        XCTAssertEqual(PetLevelPolicy.levelStartExperience(level: 0), 0)
        XCTAssertEqual(PetLevelPolicy.levelStartExperience(level: 1), 100)
        XCTAssertEqual(PetLevelPolicy.levelStartExperience(level: 2), 300)
        XCTAssertEqual(PetLevelPolicy.levelStartExperience(level: 3), 600)
    }

    func test_레벨0은_99에서_승급할_수_없고_100에서_가능하다() {
        XCTAssertFalse(PetLevelPolicy.canLevelUp(makePet(level: 0, totalExperience: 99)))
        XCTAssertTrue(PetLevelPolicy.canLevelUp(makePet(level: 0, totalExperience: 100)))
    }

    func test_레벨1은_누적_300이_필요하다() {
        XCTAssertFalse(PetLevelPolicy.canLevelUp(makePet(level: 1, totalExperience: 299)))
        XCTAssertTrue(PetLevelPolicy.canLevelUp(makePet(level: 1, totalExperience: 300)))
    }

    func test_게이지는_0에서_1로_제한된다() {
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, totalExperience: 0)), 0, accuracy: 0.001)
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, totalExperience: 50)), 0.5, accuracy: 0.001)
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, totalExperience: 250)), 1, accuracy: 0.001)
    }

    func test_초과_경험치는_다음_레벨_게이지로_이월된다() {
        // 레벨 0에서 250을 모아 승급하면 레벨 1 진행분이 150 남는다
        XCTAssertEqual(PetLevelPolicy.currentExperience(makePet(level: 1, totalExperience: 250)), 150)
    }

    func test_여러_레벨_분량이면_승급_후에도_버튼이_유지된다() {
        var pet = makePet(level: 0, totalExperience: 300)
        XCTAssertTrue(PetLevelPolicy.canLevelUp(pet))

        pet.level += 1
        // 레벨 1 진행분 200 == 요구량 200
        XCTAssertTrue(PetLevelPolicy.canLevelUp(pet))

        pet.level += 1
        // 레벨 2 진행분 0 < 요구량 300
        XCTAssertFalse(PetLevelPolicy.canLevelUp(pet))
    }
}
