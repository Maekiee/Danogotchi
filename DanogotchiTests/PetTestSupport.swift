import Foundation
@testable import Danogotchi


/// 정책 함수가 `now`를 인자로 받으므로 고정 시각만 있으면 된다 — Clock 추상화는 만들지 않는다.
let testBase = Date(timeIntervalSince1970: 1_700_000_000)

func hoursLater(_ hours: Double) -> Date {
    testBase.addingTimeInterval(hours * 3600)
}

func makePet(
    level: Int = 0,
    totalExperience: Int = 0,
    satiety: Double = 100,
    hydration: Double = 100,
    fun: Double = 100,
    cleanliness: Double = 100,
    hp: Double = PetStatePolicy.maxHP,
    stateUpdatedAt: Date = testBase
) -> Pet {
    Pet(
        id: UUID(),
        type: .sprout,
        name: "테스트",
        level: level,
        totalExperience: totalExperience,
        satiety: satiety,
        hydration: hydration,
        fun: fun,
        cleanliness: cleanliness,
        hp: hp,
        stateUpdatedAt: stateUpdatedAt,
        createAt: testBase
    )
}

/// 결과 종류와 무관하게 정산된 Pet을 꺼낸다 — 어느 결과든 저장 대상이다.
func petAfterCare(_ pet: Pet, _ stat: PetCareStat, _ now: Date) -> Pet {
    switch PetStatePolicy.care(pet, stat: stat, now: now) {
    case .success(let updated), .alreadyFull(let updated), .dead(let updated):
        return updated
    }
}
