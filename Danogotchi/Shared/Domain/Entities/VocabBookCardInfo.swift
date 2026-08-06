import Foundation

/// Library 카드 1장. BookTopic을 그대로 들고 있어 색/아이콘/제목은 BookTopic+Extension을 계속 쓴다.
/// isActive가 저장 프로퍼티이므로 합성 Hashable에 포함된다 — diffable이 활성 전환을 변경으로 인식하는 근거다.
struct VocabBookCardInfo: Hashable {
    let id: UUID
    let topic: BookTopic
    let isActive: Bool
}
