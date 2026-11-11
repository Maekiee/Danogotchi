import Foundation


/// 하트 한 칸의 채움 정도. HP 1 = 1칸이고 하트 하나가 4칸이다.
enum PetHeartFill {
    case empty
    case oneThird
    case half
    case twoThirds
    case full
}


/// HP를 하트 표시로 옮기는 계산. 저장하지 않고 `hp` 하나에서 파생한다.
enum PetHeartPolicy {

    static let unitsPerHeart = 4

    /// maxHP 40 ÷ 4 = 10개. maxHP가 바뀌면 하트 수도 따라간다.
    static var heartCount: Int {
        Int(PetStatePolicy.maxHP) / unitsPerHeart
    }

    /// 항상 `heartCount`개를 돌려준다. 뒤쪽 `.empty`는 HP 단계가 아니라 빈 배경 슬롯이다.
    static func hearts(hp: Double) -> [PetHeartFill] {
        // `0 < hp < 1`에서도 1칸을 남긴다 — 하트가 전부 사라지는 건 `hp == 0`뿐이다.
        let units = hp <= 0 ? 0 : max(1, Int(floor(hp)))
        let fullCount = units / unitsPerHeart
        let remainder = units % unitsPerHeart

        return (0..<heartCount).map { index in
            if index < fullCount { return .full }
            guard index == fullCount else { return .empty }

            switch remainder {
            case 3: return .twoThirds
            case 2: return .half
            case 1: return .oneThird
            default: return .empty
            }
        }
    }
}
