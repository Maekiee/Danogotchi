import Foundation

/// 알 슬롯 1칸. `petType == nil`이 개발중 슬롯이다 — 미래 PetType을 미리 만들지 않는다.
/// index가 저장 프로퍼티라서 개발중 8칸이 diffable에서 서로 다른 항목이 된다.
struct OnboardingEggItem: Hashable {
    let index: Int
    let petType: PetType?
    let isSelected: Bool

    var isComingSoon: Bool { petType == nil }
}
