import Foundation

enum PetType: String, CaseIterable {
    case sprout

    var title: String {
        switch self {
        case .sprout:
            return "새싹이"
        }
    }

    /// 에셋 이름. 테스트용 ExmapleDragon 스프라이트 시트의 첫 프레임을 임시로 쓴다 —
    /// 실제 캐릭터 에셋이 들어오면 바꿀 곳은 이 문자열 하나뿐이다.
    var imageName: String {
        switch self {
        case .sprout:
            return "spritesheet0"
        }
    }

    /// 알 에셋 이름. 이미지가 없어 셀에서 SF Symbol로 대체된다.
    var eggImageName: String {
        switch self {
        case .sprout:
            return "egg_sprout"
        }
    }
}
