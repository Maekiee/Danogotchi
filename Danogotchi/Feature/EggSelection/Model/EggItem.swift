import Foundation

struct EggItem: Hashable {
    let index: Int
    let petType: PetType?
    let isSelected: Bool
    var isComingSoon: Bool { petType == nil }
}
