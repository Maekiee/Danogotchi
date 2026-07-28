import Foundation

protocol DeleteVocabUseCase {
    func execute(vocab: Vocab)
}

final class DefaultDeleteVocabUseCase: DeleteVocabUseCase {
    private let vocabRepository: VocabRepository
    private let vocabBookRepository: VocabBookRepository
    private let userInfo: UserInfoManager

    init(
        vocabRepository: VocabRepository,
        vocabBookRepository: VocabBookRepository,
        userInfo: UserInfoManager
    ) {
        self.vocabRepository = vocabRepository
        self.vocabBookRepository = vocabBookRepository
        self.userInfo = userInfo
    }

    func execute(vocab: Vocab) {
        vocabRepository.deleteVocab(id: vocab.id)
        clearQuizStateIfActive()
    }

    /// 나의 단어장이 활성 단어장이면 진행 중인 퀴즈의 단어 id 목록이 깨지므로 상태를 버린다.
    private func clearQuizStateIfActive() {
        guard let myBook = vocabBookRepository.readAllBooks(bookType: .myBook).first,
              userInfo.activeBookIdentifier?.id == myBook.id.uuidString else { return }
        userInfo.clearQuizState()
    }
}
