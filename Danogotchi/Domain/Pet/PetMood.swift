import Foundation

/// 저장하지 않고 최신 돌봄 수치에서 매번 계산한다. 판정 순서는 `PetStatePolicy`가 갖는다.
enum PetMood: String, CaseIterable {
    case happy
    case satisfied
    case hungry
    case thirsty
    case bored
    case unpleasant
    case refreshed
    case sad
    case depressed
}
