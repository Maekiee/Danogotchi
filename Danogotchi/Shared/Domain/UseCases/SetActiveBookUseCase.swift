import Foundation
import RxSwift

protocol SetActiveBookUseCase {
    /// 해당 토픽의 단어장을 활성 단어장으로 지정하고 성공 여부를 반환한다. 단어장이 없으면 false.
    func execute(topic: BookTopic) -> Observable<Result<Bool, Error>>
}

final class DefaultSetActiveBookUseCase: SetActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(topic: BookTopic) -> Observable<Result<Bool, Error>> {
        return .deferred { [vocabBookRepository] in
            .just(Result {
                guard let book = try vocabBookRepository.readAllBooks(bookType: topic).first else {
                    throw PersistenceError.entityNotFound
                }
                try vocabBookRepository.setActiveBook(id: book.id)
                return true
            })
        }
    }
}
