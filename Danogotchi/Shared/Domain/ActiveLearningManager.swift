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
    private let recommendRepo: RecommendBookRepository
    private let userInfo: UserInfoManager
    private let disposeBag = DisposeBag()

    init(
        wordBookRepo: VocabBookRepository = DefaultVocabBookRepository(
            context: CoreDataStack.shared.viewContext
        ),
        recommendRepo: RecommendBookRepository = DefaultRecommendBookRepository(),
        userInfo: UserInfoManager = UserInfoManager.shared
    ) {
        self.vocabBookRepo = wordBookRepo
        self.recommendRepo = recommendRepo
        self.userInfo = userInfo
        
        userInfo.activeBookIdentifierRelay
            .flatMapLatest { [weak self] identifier -> Observable<(VocabBook?, VocabularyBookType?)> in
                guard let self = self, let identifier = identifier else {
                    return .just((nil, nil)) // 선택된 책 없음
                }
                
                switch identifier.type {
                case .mine:
                    guard let uuid = UUID(uuidString: identifier.id) else {
                        return .just((nil, nil))
                    }
                    let source: VocabularyBookType = .mine(id: uuid)
                    return self.loadMyBook(id: uuid).map { ($0, $0 != nil ? source : nil) }
                case .recommended:
                    let source: VocabularyBookType = .recommended(id: identifier.id)
                    return self.loadRecommendedBook(id: identifier.id).map { ($0, $0 != nil ? source : nil) }
                }
            }
            .subscribe(with: self, onNext: { owner, result in
                let (book, source) = result
                owner.activeBook.accept(book)
                owner.activeBookSource.accept(source)
            })
            .disposed(by: disposeBag)
    }

    private func loadMyBook(id: UUID) -> Observable<VocabBook?> {
        guard let book = vocabBookRepo.readBook(id: id) else {
            return .just(nil)
        }

        let vocabs = vocabBookRepo.fetchVocabs(inBookId: id)
        let vocabBook = VocabBook(
            id: book.id,
            title: book.title,
            type: book.type,
            originBookId: book.originBookId,
            vocabList: vocabs,
            createAt: book.createAt
        )

        return .just(vocabBook)
    }
    
    // Helper: 추천 단어장 로드 (MockRepo에서 ID로 검색)
    private func loadRecommendedBook(id: String) -> Observable<VocabBook?> {
        return recommendRepo.fetchRecommendBooks()
            .map { allBooks in
                allBooks.first(where: { $0.originBookId == id || $0.id.uuidString == id })
            }
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
