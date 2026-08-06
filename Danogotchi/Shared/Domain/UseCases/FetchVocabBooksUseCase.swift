import Foundation
import RxSwift

protocol FetchVocabBooksUseCase {
    /// 활성 단어장 변경 신호. 값 캐시가 아니므로 신호를 받으면 execute()로 다시 읽는다.
    var activeBookChanged: Observable<Void> { get }
    /// 전체 단어장 목록. 각 카드에 학습중 여부(isActive)를 함께 싣는다.
    func execute() -> Observable<[VocabBookCardInfo]>
}

final class DefaultFetchVocabBooksUseCase: FetchVocabBooksUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    var activeBookChanged: Observable<Void> {
        return vocabBookRepository.activeBookId.map { _ in () }
    }

    func execute() -> Observable<[VocabBookCardInfo]> {
        return .just(
            vocabBookRepository.readAllBooks().map {
                VocabBookCardInfo(id: $0.id, topic: $0.bookType, isActive: $0.isActive)
            }
        )
    }
}
