import XCTest
@testable import Danogotchi


final class PetLevelPolicyTests: XCTestCase {

    func test_레벨별_요구_경험치는_고정_표를_따른다() {
        let expected = [1_000, 2_105, 3_347, 5_063, 7_423, 10_639, 36_189]
        for (level, required) in expected.enumerated() {
            XCTAssertEqual(PetLevelPolicy.requiredExperience(level: level), required, "레벨 \(level)")
        }
    }

    func test_레벨0은_999에서_승급할_수_없고_1000에서_가능하다() {
        XCTAssertFalse(PetLevelPolicy.canLevelUp(makePet(level: 0, experience: 999)))
        XCTAssertTrue(PetLevelPolicy.canLevelUp(makePet(level: 0, experience: 1_000)))
    }

    func test_레벨1은_2105가_필요하다() {
        XCTAssertFalse(PetLevelPolicy.canLevelUp(makePet(level: 1, experience: 2_104)))
        XCTAssertTrue(PetLevelPolicy.canLevelUp(makePet(level: 1, experience: 2_105)))
    }

    func test_최고_레벨은_7이고_더_오를_수_없다() {
        let maxed = makePet(level: 7, experience: 999_999)

        XCTAssertTrue(PetLevelPolicy.isMaxLevel(maxed.level))
        XCTAssertFalse(PetLevelPolicy.canLevelUp(maxed))
        // 더 채울 곳이 없으므로 게이지는 항상 가득 찬 것으로 본다
        XCTAssertEqual(PetLevelPolicy.progress(maxed), 1, accuracy: 0.001)
    }

    func test_레벨6은_아직_최고_레벨이_아니다() {
        XCTAssertFalse(PetLevelPolicy.isMaxLevel(6))
        XCTAssertTrue(PetLevelPolicy.canLevelUp(makePet(level: 6, experience: 36_189)))
    }

    func test_게이지는_0에서_1로_제한된다() {
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, experience: 0)), 0, accuracy: 0.001)
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, experience: 500)), 0.5, accuracy: 0.001)
        XCTAssertEqual(PetLevelPolicy.progress(makePet(level: 0, experience: 2_500)), 1, accuracy: 0.001)
    }

    func test_승급하면_경험치가_0이_되어_연속_승급이_불가하다() {
        // 요구량의 두 배를 모아도 초과분은 이월되지 않는다
        var pet = makePet(level: 0, experience: 3_000)
        XCTAssertTrue(PetLevelPolicy.canLevelUp(pet))

        pet.level += 1
        pet.experience = 0

        XCTAssertFalse(PetLevelPolicy.canLevelUp(pet))
        XCTAssertEqual(PetLevelPolicy.progress(pet), 0, accuracy: 0.001)
    }
}
