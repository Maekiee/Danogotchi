import Foundation

/// 누적 포인트는 정수 하나라 UserDefaults에 둔다.
/// ponytail: 펫 육성이 레벨/성장 이력까지 갖게 되면 CoreData 엔티티로 옮긴다.
final class DefaultExperienceRepository: ExperienceRepository {
    private enum Keys {
        static let totalPoint = "experienceTotalPoint"
    }

    func addPoint(_ amount: Int) -> Int {
        let updated = UserDefaults.standard.integer(forKey: Keys.totalPoint) + amount
        UserDefaults.standard.set(updated, forKey: Keys.totalPoint)
        return updated
    }
}
