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
            experience: Int(totalExperience), // CoreData 속성명은 `totalExperience`로 남아 있지만 담긴 값은 현재 레벨 경험치다
            satiety: satiety,
            hydration: hydration,
            fun: fun,
            cleanliness: cleanliness,
            hp: hp,
            stateUpdatedAt: stateUpdatedAt,
            createAt: createAt
        )
    }

    func apply(_ pet: Pet) {
        id = pet.id
        type = pet.type.rawValue
        name = pet.name
        level = Int64(pet.level)
        totalExperience = Int64(pet.experience)
        satiety = pet.satiety
        hydration = pet.hydration
        fun = pet.fun
        cleanliness = pet.cleanliness
        hp = pet.hp
        stateUpdatedAt = pet.stateUpdatedAt
        createAt = pet.createAt
    }
}
