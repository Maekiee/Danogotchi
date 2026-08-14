import Foundation


protocol FetchPetStateUseCase {
    /// 현재 시각까지 정산한 뒤 저장하고 표시 정보를 돌려준다. 펫이 없으면 nil.
    func execute() -> PetDisplayInfo?
}

final class DefaultFetchPetStateUseCase: FetchPetStateUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    /// 조회가 곧 정산이므로 읽기만 해도 저장한다 — 저장하지 않으면 다음 조회가 같은 경과 시간을 다시 적용한다.
    func execute() -> PetDisplayInfo? {
        guard let pet = petRepository.readPet() else { return nil }

        let settled = PetStatePolicy.settle(pet, now: Date())
        petRepository.updatePet(settled)

        return PetDisplayInfo(pet: settled)
    }
}
