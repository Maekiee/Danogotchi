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
            return "갈증"
        case .fun:
            return "즐거움"
        case .cleanliness:
            return "청결"
        }
    }

    /// 정산·돌보기가 네 수치를 같은 코드로 다루기 위한 매핑
    var keyPath: WritableKeyPath<Pet, Double> {
        switch self {
        case .satiety:
            return \.satiety
        case .hydration:
            return \.hydration
        case .fun:
            return \.fun
        case .cleanliness:
            return \.cleanliness
        }
    }
}
