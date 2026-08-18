import Foundation


protocol CreatePetUseCase {
    /// 온보딩에서 펫을 만든다. 이미 있으면 만들지 않고 기존 펫을 돌려준다. 저장에 실패하면 nil.
    func execute(type: PetType, name: String) -> Pet?
}

final class DefaultCreatePetUseCase: CreatePetUseCase {
    private let petRepository: PetRepository

    init(petRepository: PetRepository) {
        self.petRepository = petRepository
    }

    /// 초기 수치는 정책 상수에서 가져와 Repository가 밸런스값을 모르게 한다.
    /// 이름 공백 제거·길이 검증은 입력 화면의 책임이라 여기서 하지 않는다.
    func execute(type: PetType, name: String) -> Pet? {
        let now = Date()
        let pet = Pet(
            id: UUID(),
            type: type,
            name: name,
            level: 0,
            experience: 0,
            satiety: PetStatePolicy.initialStat,
            hydration: PetStatePolicy.initialStat,
            fun: PetStatePolicy.initialStat,
            cleanliness: PetStatePolicy.initialStat,
            hp: PetStatePolicy.maxHP,
            stateUpdatedAt: now,
            createAt: now
        )

        return petRepository.createPet(pet)
    }
}
