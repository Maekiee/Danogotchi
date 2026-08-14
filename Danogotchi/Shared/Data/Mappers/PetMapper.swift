import Foundation

extension PetEntity {
    func toDomain() -> Pet {
        guard let id = id,
              let name = name,
              let typeRawValue = type,
              let type = PetType(rawValue: typeRawValue),
              let stateUpdatedAt = stateUpdatedAt,
              let createAt = createAt else {
            preconditionFailure("PetEntity required property is nil")
        }

        return Pet(
            id: id,
            type: type,
            name: name,
            level: Int(level),
            totalExperience: Int(totalExperience),
            satiety: satiety,
            hydration: hydration,
            fun: fun,
            cleanliness: cleanliness,
            hp: hp,
            stateUpdatedAt: stateUpdatedAt,
            createAt: createAt
        )
    }

    /// 도메인 값으로 필드를 덮어쓴다. 생성과 전체 저장이 같은 코드를 쓰도록 매퍼에 둔다.
    func apply(_ pet: Pet) {
        id = pet.id
        type = pet.type.rawValue
        name = pet.name
        level = Int64(pet.level)
        totalExperience = Int64(pet.totalExperience)
        satiety = pet.satiety
        hydration = pet.hydration
        fun = pet.fun
        cleanliness = pet.cleanliness
        hp = pet.hp
        stateUpdatedAt = pet.stateUpdatedAt
        createAt = pet.createAt
    }
}
