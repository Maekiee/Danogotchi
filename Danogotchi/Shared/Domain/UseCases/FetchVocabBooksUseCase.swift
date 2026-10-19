import Foundation

protocol FetchVocabBooksUseCase {
    /// 활성 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 execute()로 다시 읽는다.
    var activeBookChanged: AsyncStream<Void> { get }
    /// 전체 단어장 목록. 각 카드에 학습중 여부(isActive)를 함께 싣는다.
    func execute() throws -> [VocabBookCardInfo]
}

final class DefaultFetchVocabBooksUseCase: FetchVocabBooksUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    var activeBookChanged: AsyncStream<Void> {
        return vocabBookRepository.activeBookChanged
    }

    func execute() throws -> [VocabBookCardInfo] {
        return try vocabBookRepository.readAllBooks().map {
            VocabBookCardInfo(id: $0.id, topic: $0.bookType, isActive: $0.isActive)
        }
    }
}
