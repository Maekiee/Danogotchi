import Foundation

/// 앱에 1마리만 존재하는 육성 대상.
struct Pet {
    let id: UUID
    let type: PetType
    let name: String
    var level: Int
    /// 현재 레벨에서 모은 경험치. 레벨업 시 0으로 초기화되고 초과분은 이월되지 않는다.
    var experience: Int
    /// 돌봄 수치 — 전부 `0...100`의 긍정 방향. `0`이 나쁨, `100`이 좋음이다.
    var satiety: Double
    var hydration: Double
    var fun: Double
    var cleanliness: Double
    /// 생명력. 위험 상태에 머문 시간만큼 줄고 `0`이 되면 사망한다.
    var hp: Double
    /// 돌봄 수치와 HP를 마지막으로 정산한 시각. 경과 시간 계산의 유일한 기준점이다.
    var stateUpdatedAt: Date
    let createAt: Date

    var isDead: Bool { hp <= 0 }
}
