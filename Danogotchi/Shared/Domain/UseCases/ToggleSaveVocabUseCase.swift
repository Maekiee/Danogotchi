import Foundation
import RxSwift

protocol ToggleSaveVocabUseCase {
    /// 추천 단어의 저장/해제를 토글하고 결과 상태(저장됨 = true)를 반환한다.
    func execute(vocab: Vocab) -> Observable<Bool>
}

final class DefaultToggleSaveVocabUseCase: ToggleSaveVocabUseCase {
    private let vocabBookRepository: VocabBookRepository
    private let vocabRepository: VocabRepository
    private let userInfo: UserInfoManager

    init(
        vocabBookRepository: VocabBookRepository,
        vocabRepository: VocabRepository,
        userInfo: UserInfoManager
    ) {
        self.vocabBookRepository = vocabBookRepository
        self.vocabRepository = vocabRepository
        self.userInfo = userInfo
    }

    func execute(vocab: Vocab) -> Observable<Bool> {
        guard let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first else {
            return .just(false)
        }

        if let savedVocab = vocabBookRepository
            .findVocab(inBookId: myBook.id, sourceWordId: vocab.id) {
            vocabRepository.deleteVocab(id: savedVocab.id)
            clearQuizStateIfActive(myBookId: myBook.id)
            return .just(false)
        }

        return .just(vocabBookRepository.addVocab(bookId: myBook.id, from: vocab) != nil)
    }

    /// 나의 단어장이 활성 단어장이면 진행 중인 퀴즈의 단어 id 목록이 깨지므로 상태를 버린다.
    /// 저장(추가)은 기존 목록을 깨지 않으므로 해제할 때만 호출한다.
    private func clearQuizStateIfActive(myBookId: UUID) {
        guard userInfo.activeBookIdentifier?.id == myBookId.uuidString else { return }
        userInfo.clearQuizState()
    }
}
