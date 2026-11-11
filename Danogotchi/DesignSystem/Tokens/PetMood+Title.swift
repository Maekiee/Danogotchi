import Foundation

extension PetMood {
    var title: String {
        switch self {
        case .happy:
            return String(localized: "행복함")
        case .satisfied:
            return String(localized: "만족함")
        case .hungry:
            return String(localized: "배고픔")
        case .thirsty:
            return String(localized: "목마름")
        case .bored:
            return String(localized: "심심함")
        case .unpleasant:
            return String(localized: "불쾌함")
        case .refreshed:
            return String(localized: "상쾌함")
        case .sad:
            return String(localized: "슬픔")
        case .depressed:
            return String(localized: "우울함")
        }
    }
}
