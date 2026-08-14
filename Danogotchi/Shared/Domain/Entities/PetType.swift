import Foundation

enum PetType: String, CaseIterable {
    case sprout

    var title: String {
        switch self {
        case .sprout:
            return "새싹이"
        }
    }

    /// 에셋 이름. 아직 이미지가 없어 호출부에서 SF Symbol로 대체된다 —
    /// 에셋을 추가할 때 바꿀 곳은 이 문자열 하나뿐이다.
    var imageName: String {
        switch self {
        case .sprout:
            return "pet_sprout"
        }
    }
}
