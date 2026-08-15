import Foundation


protocol IsPetCreatedUseCase {
    /// 펫이 이미 있는지 여부. 온보딩 재진입 분기 전용이라 상태를 정산하지도 저장하지도 않는다.
    func execute() -> Bool
}

final class DefaultIsPetCreatedUseCase: IsPetCreatedUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    func execute() -> Bool {
        return petRepository.readPet() != nil
    }
}
