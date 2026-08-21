import Foundation


protocol AdjustPetLevelUseCase {
    /// 요구 경험치를 무시하고 레벨만 옮긴다. 펫이 없으면 nil.
    func execute(delta: Int) -> PetActionResult?
}

/// dev 빌드의 테스트 버튼만 호출한다 — 레벨별 시트와 레벨 관련 UI를 경험치 없이 확인하는 통로다.
/// 경험치는 건드리지 않는다. 레벨업 버튼의 활성 조건까지 그대로 재현하려면 경험치가 남아 있어야 한다.
final class DefaultAdjustPetLevelUseCase: AdjustPetLevelUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    func execute(delta: Int) -> PetActionResult? {
        guard let pet = petRepository.readPet() else { return nil }

        // 다른 쓰기 경로와 같이 정산부터 한다 — 저장은 한 번이면 된다
        var settled = PetStatePolicy.settle(pet, now: Date())
        // 정책 범위를 넘기면 시트가 없는 레벨이 된다
        settled.level = min(max(0, settled.level + delta), PetLevelPolicy.maxLevel)
        petRepository.updatePet(settled)

        return PetActionResult(info: PetDisplayInfo(pet: settled), rejection: nil)
    }
}
