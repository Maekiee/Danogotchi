import Foundation


protocol LevelUpPetUseCase {
    /// 정산 후 요구 경험치를 재검사하고 통과 시에만 레벨을 올린다. 펫이 없으면 nil.
    func execute() -> PetActionResult?
}

final class DefaultLevelUpPetUseCase: LevelUpPetUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    /// 버튼 활성 상태를 신뢰하지 않고 저장 직전에 다시 검사한다.
    /// 레벨만 올리고 누적 경험치는 그대로 둬 초과분이 다음 레벨 게이지로 이월된다.
    func execute() -> PetActionResult? {
        guard let pet = petRepository.readPet() else { return nil }

        var settled = PetStatePolicy.settle(pet, now: Date())
        let canLevelUp = PetLevelPolicy.canLevelUp(settled)
        if canLevelUp {
            settled.level += 1
        }

        petRepository.updatePet(settled)

        return PetActionResult(
            info: PetDisplayInfo(pet: settled),
            rejection: canLevelUp ? nil : .notEnoughExperience
        )
    }
}
