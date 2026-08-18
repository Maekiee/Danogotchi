import UIKit

extension PetCareStat {
    var color: UIColor {
        switch self {
        case .satiety:
            return AppColor.butter
        case .hydration:
            return AppColor.sky
        case .fun:
            return AppColor.coral
        case .cleanliness:
            return AppColor.sage
        }
    }

    /// 돌보기 버튼 문구. 수치 이름(`title`)과 달리 행동을 가리킨다.
    var actionTitle: String {
        switch self {
        case .satiety:
            return "밥주기"
        case .hydration:
            return "물주기"
        case .fun:
            return "놀아주기"
        case .cleanliness:
            return "청소하기"
        }
    }
}
