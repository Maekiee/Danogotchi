import Foundation

struct PetActionResult {
    let info: PetDisplayInfo
    let rejection: PetActionRejection?
}

enum PetActionRejection {
    case alreadyFull
    case dead
    case notEnoughExperience
    case alive
}
