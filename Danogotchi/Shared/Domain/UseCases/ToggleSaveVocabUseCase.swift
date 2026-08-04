import Foundation
import RxSwift

protocol ToggleSaveVocabUseCase {
    /// 추천 단어의 저장/해제를 토글하고 결과 상태(저장됨 = true)를 반환한다.
    func execute(vocab: Vocab) -> Observable<Bool>
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

    func execute(vocab: Vocab) -> Observable<Bool> {
        guard let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first else {
            return .just(false)
        }

        if let savedVocab = vocabBookRepository
            .findVocab(inBookId: myBook.id, sourceWordId: vocab.id) {
            vocabRepository.deleteVocab(id: savedVocab.id)
            return .just(false)
        }

        return .just(vocabBookRepository.addVocab(bookId: myBook.id, from: vocab) != nil)
    }
}
