import Foundation
import RxSwift

protocol ToggleSaveVocabUseCase {
    /// 추천 단어의 저장/해제를 토글하고 결과 상태(저장됨 = true)를 반환한다.
    func execute(vocab: Vocab) -> Observable<Result<Bool, Error>>
}

final class DefaultToggleSaveVocabUseCase: ToggleSaveVocabUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let vocabRepository: VocabRepository

    init(
        vocabBookRepository: VocabBookRepository,
        vocabRepository: VocabRepository
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.vocabRepository = vocabRepository
    }

    func execute(vocab: Vocab) -> Observable<Result<Bool, Error>> {
        return .deferred { [vocabBookRepository, vocabRepository] in
            .just(Result {
                guard let myBook = try vocabBookRepository.readAllBooks(bookType: .myBook).first else {
                    throw PersistenceError.entityNotFound
                }
                if let savedVocab = try vocabBookRepository.findVocab(inBookId: myBook.id, sourceWordId: vocab.id) {
                    try vocabRepository.deleteVocab(id: savedVocab.id)
                    return false
                }
                _ = try vocabBookRepository.addVocab(bookId: myBook.id, from: vocab)
                return true
            })
        }
    }
}
