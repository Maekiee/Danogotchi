import Foundation

/// 네 돌보기 버튼이 같은 처리 경로를 타도록 대상 수치를 하나의 타입으로 표현한다.
enum PetCareStat: String, CaseIterable {
    case satiety
    case hydration
    case fun
    case cleanliness

    var title: String {
        switch self {
        case .satiety:
            return "포만감"
        case .hydration:
            return "수분"
        case .fun:
            return "즐거움"
        case .cleanliness:
            return "청결"
        }
    }
}
