import Foundation

/// 서버에서 받을 수 있는 단어장 목록 항목
struct RemoteVocabBook: Hashable {
    let key: VocabBookKey
    let wordCount: Int
    let order: Int
}
