import Foundation


protocol RevivePetUseCase {
    /// 사망 상태에서만 HP·돌봄 수치를 복구하고 경험치 페널티를 매긴다. 펫이 없으면 nil.
    func execute() -> PetActionResult?
}

final class DefaultRevivePetUseCase: RevivePetUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    /// 정책이 복구와 페널티를 모두 반영한 Pet 하나를 돌려주므로 저장은 한 번이면 된다.
    func execute() -> PetActionResult? {
        guard let pet = petRepository.readPet() else { return nil }

        let settled: Pet
        let rejection: PetActionRejection?
        switch PetStatePolicy.revive(pet, now: Date()) {
        case .success(let updated):
            settled = updated
            rejection = nil
        case .alive(let updated):
            settled = updated
            rejection = .alive
        }

        petRepository.updatePet(settled)

        return PetActionResult(info: PetDisplayInfo(pet: settled), rejection: rejection)
    }
}
