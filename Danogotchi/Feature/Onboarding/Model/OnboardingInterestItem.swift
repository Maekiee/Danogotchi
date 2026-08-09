import Foundation

/// 관심사 카드 1장. isSelected가 저장 프로퍼티이므로 합성 Hashable에 포함된다 — diffable이 선택 전환을 변경으로 인식하는 근거다.
struct OnboardingInterestItem: Hashable {
    let topic: BookTopic
    let isSelected: Bool
}
