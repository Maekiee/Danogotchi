import Foundation
import XCTest
@testable import Danogotchi

let travelA1 = VocabBookKey(topic: .travel, level: .a1)
let businessA1 = VocabBookKey(topic: .business, level: .a1)
let lifeA1 = VocabBookKey(topic: .life, level: .a1)

/// 원격 단어장 대역 — 결과를 바꿀 수 있고 단어 조회 호출을 기록한다
final class ControlledRemoteVocabBookRepository: RemoteVocabBookRepository {
    var books: Result<[RemoteVocabBook], Error> = .success([])
    var vocabs: [VocabBookKey: [Vocab]] = [:]
    var vocabsError: Error?
    /// 응답 직전에 불린다 — 받는 사이 다른 화면이 저장한 상황을 만든다
    var beforeVocabsResponse: (() throws -> Void)?
    private(set) var fetchBooksCount = 0
    private(set) var fetchedKeys: [VocabBookKey] = []

    // 앱 타깃의 비격리 async는 백그라운드에서 돈다 — 기록과 CoreData 훅이 테스트와 같은 메인에서 돌게 한다
    @MainActor
    func fetchBooks() async throws -> [RemoteVocabBook] {
        fetchBooksCount += 1
        return try books.get()
    }

    @MainActor
    func fetchVocabs(key: VocabBookKey) async throws -> [Vocab] {
        fetchedKeys.append(key)
        try beforeVocabsResponse?()
        if let vocabsError { throw vocabsError }
        return vocabs[key] ?? []
    }
}

/// 서버가 내려주는 형태의 단어 — 대역에 담아 두면 몇 번을 받아도 id가 같다
func makeServerVocabs(_ key: VocabBookKey, words: [String]) -> [Vocab] {
    words.enumerated().map { index, word in
        Vocab(id: UUID(), word: word, meaning: "\(word) 뜻", bookType: key.topic, level: key.level,
              partOfSpeech: .noun, sourceWordId: nil, createAt: testBase.addingTimeInterval(Double(index)))
    }
}

/// VM이 Task로 돌린 비동기 작업이 끝나 조건이 참이 될 때까지 메인 액터에서 기다린다
@MainActor
func waitUntil(timeout: TimeInterval = 2, file: StaticString = #filePath, line: UInt = #line,
               _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else { return XCTFail("조건을 기다리다 시간 초과", file: file, line: line) }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}
