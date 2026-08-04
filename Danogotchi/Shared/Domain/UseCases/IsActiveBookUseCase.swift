import Foundation
import RxSwift

protocol IsActiveBookUseCase {
    /// 해당 토픽의 단어장이 현재 활성 단어장인지 여부. 단어장이 없으면 false.
    func execute(topic: BookTopic) -> Observable<Bool>
}

final class DefaultIsActiveBookUseCase: IsActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(topic: BookTopic) -> Observable<Bool> {
        return .just(vocabBookRepository.readAllBooks(bookType: topic).first?.isActive ?? false)
    }
}
