import Foundation

struct PetDisplayInfo {
    let pet: Pet
    let mood: PetMood
    let progress: Double
    let canLevelUp: Bool
    let isMaxLevel: Bool
    let hearts: [PetHeartFill]
}


extension PetDisplayInfo {
    init(pet: Pet) {
        self.init(
            pet: pet,
            mood: PetStatePolicy.mood(pet),
            progress: PetLevelPolicy.progress(pet),
            canLevelUp: PetLevelPolicy.canLevelUp(pet),
            isMaxLevel: PetLevelPolicy.isMaxLevel(pet.level),
            hearts: PetHeartPolicy.hearts(hp: pet.hp)
        )
    }
}
