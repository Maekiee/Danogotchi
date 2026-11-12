import Foundation

/// 단어 없이 읽는 단어장 정보 — 받았는지·학습중인지 확인할 때 단어를 읽지 않게
struct VocabBookSummary {
    let id: UUID
    let key: VocabBookKey
    let isActive: Bool
}
