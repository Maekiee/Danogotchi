import Foundation


/// 캐릭터 화면 한 번의 렌더링에 필요한 값. 정산이 끝난 `Pet`과 정책이 계산한 파생값을 함께 싣는다.
/// 이름·레벨·HP·네 돌봄 수치·사망 여부는 `pet`에서 그대로 읽는다 — 12개 필드를 다시 나열하지 않는다.
struct PetDisplayInfo {
    let pet: Pet
    let mood: PetMood
    let progress: Double
    let canLevelUp: Bool
    /// 최고 레벨이면 레벨업 버튼 자체를 숨긴다
    let isMaxLevel: Bool
    /// 항상 10칸. HP를 그대로 두고 표시 단계만 파생한 값이다.
    let hearts: [PetHeartFill]
}


extension PetDisplayInfo {
    /// **정산이 끝난** Pet에서 파생값을 계산한다. UseCase마다 같은 조립을 반복하지 않게 여기 모은다.
    init(pet: Pet) {
        self.init(
            pet: pet,
            mood: PetStatePolicy.mood(pet),
            progress: PetLevelPolicy.progress(pet),
            canLevelUp: PetLevelPolicy.canLevelUp(pet),
            isMaxLevel: PetLevelPolicy.isMaxLevel(pet.level),
            hearts: PetHeartPolicy.hearts(hp: pet.hp)
        )
    }
}
