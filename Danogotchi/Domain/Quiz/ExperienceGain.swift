import Foundation

struct ExperienceGain {
    let earned: Int
    let perfectBonus: Int
    var total: Int { earned + perfectBonus }
}
