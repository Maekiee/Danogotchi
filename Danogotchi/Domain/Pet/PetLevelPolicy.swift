import Foundation


/// 레벨 요구량은 표로 고정돼 있고 Lv.7이 마지막이다.
/// 레벨업은 자동으로 처리하지 않으므로 여기서는 조건 판정까지만 한다.
enum PetLevelPolicy {

    /// 마지막 레벨. 여기 도달하면 더 올릴 수 없다.
    static let maxLevel = 7

    /// index = 현재 레벨. `[0]`이 0→1, 마지막이 6→7이다.
    private static let requirements = [1_000, 2_105, 3_347, 5_063, 7_423, 10_639, 36_189]

    static func isMaxLevel(_ level: Int) -> Bool {
        level >= maxLevel
    }

    /// 다음 레벨까지 필요한 경험치. 최고 레벨은 다음이 없어 마지막 요구량을 그대로 돌려준다
    /// — 부활 페널티 기준으로만 쓰인다.
    static func requiredExperience(level: Int) -> Int {
        requirements[min(max(0, level), requirements.count - 1)]
    }

    /// 게이지 진행률. 최고 레벨은 더 채울 곳이 없으므로 항상 가득 찬 것으로 본다.
    static func progress(_ pet: Pet) -> Double {
        guard !isMaxLevel(pet.level) else { return 1 }
        return min(1, Double(pet.experience) / Double(requiredExperience(level: pet.level)))
    }

    static func canLevelUp(_ pet: Pet) -> Bool {
        !isMaxLevel(pet.level) && pet.experience >= requiredExperience(level: pet.level)
    }
}
