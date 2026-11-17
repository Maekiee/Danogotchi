import Foundation

struct Pet {
    let id: UUID
    let type: PetType
    let name: String
    var level: Int
    var experience: Int
    var satiety: Double
    var hydration: Double
    var fun: Double
    var cleanliness: Double
    var hp: Double
    var stateUpdatedAt: Date
    let createAt: Date
    var isDead: Bool { hp <= 0 }
}
