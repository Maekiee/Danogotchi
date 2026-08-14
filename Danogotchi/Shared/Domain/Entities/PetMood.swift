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
            return "행복함"
        case .satisfied:
            return "만족함"
        case .hungry:
            return "배고픔"
        case .thirsty:
            return "목마름"
        case .bored:
            return "심심함"
        case .unpleasant:
            return "불쾌함"
        case .refreshed:
            return "상쾌함"
        case .sad:
            return "슬픔"
        case .depressed:
            return "우울함"
        }
    }
}
