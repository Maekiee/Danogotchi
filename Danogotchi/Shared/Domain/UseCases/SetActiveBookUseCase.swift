import Foundation
import RxSwift

protocol SetActiveBookUseCase {
    /// 해당 토픽의 단어장을 활성 단어장으로 지정하고 성공 여부를 반환한다. 단어장이 없으면 false.
    func execute(topic: BookTopic) -> Observable<Bool>
}

final class DefaultSetActiveBookUseCase: SetActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(topic: BookTopic) -> Observable<Bool> {
        guard let book = vocabBookRepository.readAllBooks(bookType: topic).first else {
            return .just(false)
        }

        // 기존 활성 단어장 해제는 setActiveBook 이 같은 트랜잭션에서 처리한다
        vocabBookRepository.setActiveBook(id: book.id)

        return .just(true)
    }
}
