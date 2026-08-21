import Foundation

enum PetType: String, CaseIterable {
    case sprout

    var title: String {
        switch self {
        case .sprout:
            return "새싹이"
        }
    }

    /// 레벨별 스프라이트 시트 이름. 시트 8장이 레벨 `0...PetLevelPolicy.maxLevel`과 1:1이다.
    /// 실제 캐릭터 에셋으로 갈아탈 때 바꿀 곳은 이 접두사 하나뿐이다.
    ///
    /// ponytail: 번들 루트가 플랫이라 시트 이름이 전역이다. 펫이 2종 이상 되면
    /// `spritesheet0`이 충돌하므로 폴더 참조로 옮기고 타입별 경로를 붙인다.
    func sheetName(level: Int) -> String {
        switch self {
        case .sprout:
            // 부활 페널티가 레벨을 내린다 — 범위를 벗어나면 이미지가 nil이 되므로 정책 상한으로 자른다
            return "spritesheet\(min(max(0, level), PetLevelPolicy.maxLevel))"
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
