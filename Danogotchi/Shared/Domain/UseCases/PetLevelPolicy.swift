import Foundation


/// 레벨 요구량은 레벨마다 100씩 늘어난다 — 0→1은 100, 1→2는 200, 2→3은 300 EXP.
/// 레벨업은 자동으로 처리하지 않으므로 여기서는 조건 판정까지만 한다.
enum PetLevelPolicy {

    static let experiencePerLevel = 100

    /// 현재 레벨에서 다음 레벨로 가는 데 필요한 경험치
    static func requiredExperience(level: Int) -> Int {
        experiencePerLevel * (level + 1)
    }

    /// 현재 레벨이 시작되는 누적 경험치 (등차수열 합)
    static func levelStartExperience(level: Int) -> Int {
        experiencePerLevel * level * (level + 1) / 2
    }

    /// 현재 레벨 안에서 모은 경험치. 레벨업 시 누적값을 깎지 않으므로 초과분이 그대로 남을 수 있다.
    static func currentExperience(_ pet: Pet) -> Int {
        max(0, pet.totalExperience - levelStartExperience(level: pet.level))
    }

    /// 게이지 진행률. 초과분은 `1`로 자른다 — 표시 텍스트는 초과분을 그대로 보여준다 (`250 / 100`).
    static func progress(_ pet: Pet) -> Double {
        let required = requiredExperience(level: pet.level)
        return min(1, Double(currentExperience(pet)) / Double(required))
    }

    static func canLevelUp(_ pet: Pet) -> Bool {
        currentExperience(pet) >= requiredExperience(level: pet.level)
    }
}
