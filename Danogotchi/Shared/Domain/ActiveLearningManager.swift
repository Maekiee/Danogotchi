import Foundation
import RxSwift
import RxCocoa

// 단어장의 출처를 명시 (ViewModel에서 분기 처리를 위해 유지)
enum VocabularyBookType {
    case mine(id: UUID)
    case recommended(id: String)
}

final class ActiveLearningManager {
    static let shared = ActiveLearningManager()
    
    // ViewModels가 구독할 최종 'VocabBook' 객체
    let activeBook = BehaviorRelay<VocabBook?>(value: nil)
    let activeBookSource = BehaviorRelay<VocabularyBookType?>(value: nil)

    private let vocabBookRepo: VocabBookRepository
    private let userInfo: UserInfoManager
    private let disposeBag = DisposeBag()

    init(
        wordBookRepo: VocabBookRepository = DefaultVocabBookRepository(
            context: CoreDataStack.shared.viewContext
        ),
        userInfo: UserInfoManager = UserInfoManager.shared
    ) {
        self.vocabBookRepo = wordBookRepo
        self.userInfo = userInfo

        userInfo.activeBookIdentifierRelay
            .flatMapLatest { [weak self] identifier -> Observable<(VocabBook?, VocabularyBookType?)> in
                guard let self = self, let identifier = identifier,
                      let uuid = UUID(uuidString: identifier.id) else {
                    return .just((nil, nil)) // 선택된 책 없음
                }

                // 시드 이후 모든 단어장이 DB에 있으므로 타입 구분 없이 id로 로드
                let source: VocabularyBookType
                switch identifier.type {
                case .mine:
                    source = .mine(id: uuid)
                case .recommended:
                    source = .recommended(id: identifier.id)
                }
                let book = self.vocabBookRepo.readBook(id: uuid)
                return .just((book, book != nil ? source : nil))
            }
            .subscribe(with: self, onNext: { owner, result in
                let (book, source) = result
                owner.activeBook.accept(book)
                owner.activeBookSource.accept(source)
            })
            .disposed(by: disposeBag)
    }

    // '활성 단어장' 변경 (ViewControllers에서 호출)
    func setActiveBook(_ book: VocabBook, source: VocabularyBookType) {
        
        if activeBook.value?.id != book.id {
            userInfo.clearQuizState()
        }
        
        let identifier: UserInfoManager.ActiveBookIdentifier
        
        switch source {
        case .mine(let id):
            identifier = .init(id: id.uuidString, type: .mine)
        case .recommended(let id):
            identifier = .init(id: id, type: .recommended)
        }
        
        // 3. UserInfoManager의 식별자(영구 저장소)를 업데이트
        // -> 이 변경이 (1)번의 구독 로직을 트리거하여 activeBook이 자동 갱신됨
        userInfo.activeBookIdentifier = identifier
    }
}
