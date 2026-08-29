import Foundation

enum PetType: String, CaseIterable {
    case sprout

    var title: String {
        switch self {
        case .sprout:
            return "새싹이"
        }
    }
    
    func sheetName(level: Int) -> String {
        switch self {
        case .sprout:
            return "spritesheet\(min(max(0, level), PetLevelPolicy.maxLevel))"
        }
    }

    var eggImageName: String {
        switch self {
        case .sprout:
            return "egg_sprout"
        }
    }
}
