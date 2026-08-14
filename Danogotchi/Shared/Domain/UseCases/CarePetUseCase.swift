import Foundation


protocol CarePetUseCase {
    /// 정산 후 대상 수치를 회복한다. 펫이 없으면 nil.
    func execute(stat: PetCareStat) -> PetActionResult?
}

final class DefaultCarePetUseCase: CarePetUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    /// 이미 100이거나 사망 상태여도 정산분은 저장한다 — 저장하지 않으면 경과 시간이 유실된다.
    func execute(stat: PetCareStat) -> PetActionResult? {
        guard let pet = petRepository.readPet() else { return nil }

        let settled: Pet
        let rejection: PetActionRejection?
        switch PetStatePolicy.care(pet, stat: stat, now: Date()) {
        case .success(let updated):
            settled = updated
            rejection = nil
        case .alreadyFull(let updated):
            settled = updated
            rejection = .alreadyFull
        case .dead(let updated):
            settled = updated
            rejection = .dead
        }

        petRepository.updatePet(settled)

        return PetActionResult(info: PetDisplayInfo(pet: settled), rejection: rejection)
    }
}
