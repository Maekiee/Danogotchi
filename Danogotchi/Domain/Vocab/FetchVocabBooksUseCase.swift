import Foundation

protocol FetchVocabBooksUseCase {
    /// 활성 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 execute(remoteBooks:)로 다시 읽는다.
    var activeBookChanged: AsyncStream<Void> { get }
    /// 서버 단어장 목록. 실패를 숨기지 않아 화면이 다시 받을지 정한다
    func fetchRemoteBooks() async throws -> [RemoteVocabBook]
    /// 나의 단어장 → 서버 목록(order 순) → 서버 목록에 없는 받은 단어장(createAt 순). 각 카드에 학습중 여부를 싣는다
    func execute(remoteBooks: [RemoteVocabBook]) throws -> [VocabBookCardInfo]
}

final class DefaultFetchVocabBooksUseCase: FetchVocabBooksUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let remoteVocabBookRepository: RemoteVocabBookRepository

    init(
        vocabBookRepository: VocabBookRepository,
        remoteVocabBookRepository: RemoteVocabBookRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.remoteVocabBookRepository = remoteVocabBookRepository
    }

    var activeBookChanged: AsyncStream<Void> {
        return vocabBookRepository.activeBookChanged
    }

    func fetchRemoteBooks() async throws -> [RemoteVocabBook] {
        return try await remoteVocabBookRepository.fetchBooks()
    }

    func execute(remoteBooks: [RemoteVocabBook]) throws -> [VocabBookCardInfo] {
        let localBooks = try vocabBookRepository.readBookSummaries()
        let localKeys = localBooks.map(\.key)
        let remoteKeys = remoteBooks.sorted { $0.order < $1.order }.map(\.key)
        let activeKeys = Set(localBooks.filter(\.isActive).map(\.key))

        // 받은 단어장은 서버 순서 자리에 한 번만 — 목록 식별자가 겹치면 화면이 그릴 수 없다
        var seen = Set<VocabBookKey>()
        let keys = (localKeys.filter { $0.topic == .myBook } + remoteKeys + localKeys).filter { seen.insert($0).inserted }
        return keys.map { VocabBookCardInfo(key: $0, isActive: activeKeys.contains($0)) }
    }
}
