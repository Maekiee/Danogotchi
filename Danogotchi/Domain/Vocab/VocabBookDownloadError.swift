import Foundation

enum VocabBookDownloadError: Error {
    /// 서버 단어가 0개 — 저장하면 받은 것으로 보여 다시 받을 수 없다
    case emptyBook
}
