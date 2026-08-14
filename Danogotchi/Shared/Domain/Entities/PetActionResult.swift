import Foundation


/// 돌보기·레벨업·부활의 결과.
/// 요청을 거절해도 정산분은 항상 저장되므로 어느 경우든 갱신된 표시 정보를 싣는다.
/// `rejection == nil`이 성공이고, 화면은 rejection 여부와 무관하게 `info`를 다시 렌더링한다.
struct PetActionResult {
    let info: PetDisplayInfo
    let rejection: PetActionRejection?
}


enum PetActionRejection {
    /// 돌보기 — 대상 수치가 이미 100
    case alreadyFull
    /// 돌보기 — 사망 상태
    case dead
    /// 레벨업 — 요구 경험치 미달
    case notEnoughExperience
    /// 부활 — 살아 있음
    case alive
}
