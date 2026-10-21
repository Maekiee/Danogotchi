import Foundation

/// 저장하지 않고 최신 돌봄 수치에서 매번 계산한다. 판정 순서는 `PetStatePolicy`가 갖는다.
enum PetMood: String, CaseIterable {
    case happy
    case satisfied
    case hungry
    case thirsty
    case bored
    case unpleasant
    case refreshed
    case sad
    case depressed

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
