import XCTest
@testable import Danogotchi


final class PetHeartPolicyTests: XCTestCase {

    private func hearts(_ hp: Double) -> [PetHeartFill] {
        PetHeartPolicy.hearts(hp: hp)
    }

    func test_하트_개수는_항상_10개다() {
        XCTAssertEqual(PetHeartPolicy.heartCount, 10)

        for hp in [40.0, 37, 20, 0.5, 0] {
            XCTAssertEqual(hearts(hp).count, 10, "hp \(hp)")
        }
    }

    func test_최대_HP는_가득_찬_하트_10개다() {
        XCTAssertEqual(hearts(40), Array(repeating: .full, count: 10))
    }

    func test_남은_칸_3_2_1은_각각_2over3_1over2_1over3이다() {
        XCTAssertEqual(hearts(39), Array(repeating: .full, count: 9) + [.twoThirds])
        XCTAssertEqual(hearts(38), Array(repeating: .full, count: 9) + [.half])
        XCTAssertEqual(hearts(37), Array(repeating: .full, count: 9) + [.oneThird])
    }

    func test_남은_칸이_0이면_부분_하트가_없다() {
        XCTAssertEqual(hearts(36), Array(repeating: .full, count: 9) + [.empty])
    }

    func test_HP가_1_미만이어도_최소_1over3_하트_하나가_남는다() {
        XCTAssertEqual(hearts(0.5), [.oneThird] + Array(repeating: .empty, count: 9))
    }

    func test_HP가_0이면_하트가_모두_소멸한다() {
        XCTAssertEqual(hearts(0), Array(repeating: .empty, count: 10))
    }

    func test_소수점은_버림한다() {
        // 37.9는 37칸과 같다 — 칸이 차오르는 건 정수 경계에서만이다
        XCTAssertEqual(hearts(37.9), hearts(37))
    }
}
