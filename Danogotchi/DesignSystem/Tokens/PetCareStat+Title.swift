import Foundation

extension PetCareStat {
    var title: String {
        switch self {
        case .satiety:
            return String(localized: "포만감")
        case .hydration:
            return String(localized: "갈증")
        case .fun:
            return String(localized: "즐거움")
        case .cleanliness:
            return String(localized: "청결")
        }
    }
}
