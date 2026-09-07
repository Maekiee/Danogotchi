import Foundation
import RxSwift

protocol IsActiveBookUseCase {
    /// 해당 토픽의 단어장이 현재 활성 단어장인지 여부. 단어장이 없으면 false.
    func execute(topic: BookTopic) -> Observable<Result<Bool, Error>>
}

final class DefaultIsActiveBookUseCase: IsActiveBookUseCase {
    private let vocabBookRepository: VocabBookRepository

    init(vocabBookRepository: VocabBookRepository) {
        self.vocabBookRepository = vocabBookRepository
    }

    func execute(topic: BookTopic) -> Observable<Result<Bool, Error>> {
        return .deferred { [vocabBookRepository] in
            .just(Result { try vocabBookRepository.readAllBooks(bookType: topic).first?.isActive ?? false })
        }
    }
}
