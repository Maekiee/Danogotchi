import Foundation

struct ExperienceGain {
    /// 정답 단어별 경험치 합계
    let earned: Int
    /// 전 문제 정답 보너스 (아니면 0)
    let perfectBonus: Int
    /// 이번 세션에서 획득한 총량
    var total: Int { earned + perfectBonus }
}
