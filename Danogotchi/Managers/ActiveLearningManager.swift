import Foundation
import RxSwift
import RxCocoa
import RealmSwift

// 단어장의 출처를 명시 (ViewModel에서 분기 처리를 위해 유지)
enum WordBookSource {
    case realm(id: String)
    case recommended(id: String)
}

final class ActiveLearningManager {
    static let shared = ActiveLearningManager()
    
    // ViewModels가 구독할 최종 'WordBook' 객체
    let activeBook = BehaviorRelay<WordBook?>(value: nil)
    
    // ViewModels가 구독할 'WordBook' 출처
    let activeBookSource = BehaviorRelay<WordBookSource?>(value: nil)

    private let wordBookRepo: WordBookRepositoryProtocol
    private let recommendRepo: RecommendBookRepoProtocol
    private let userInfo: UserInfoManager
    private let disposeBag = DisposeBag()

    init(
        wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
        recommendRepo: RecommendBookRepoProtocol = RecommendBookRepository(),
        userInfo: UserInfoManager = UserInfoManager.shared
    ) {
        self.wordBookRepo = wordBookRepo
        self.recommendRepo = recommendRepo
        self.userInfo = userInfo
        
        userInfo.activeBookIdentifierRelay
            .flatMapLatest { [weak self] identifier -> Observable<(WordBook?, WordBookSource?)> in
                guard let self = self, let identifier = identifier else {
                    return .just((nil, nil)) // 선택된 책 없음
                }
                
                switch identifier.type {
                case .realm:
                    let source: WordBookSource = .realm(id: identifier.id)
                    return self.loadRealmBook(id: identifier.id).map { ($0, $0 != nil ? source : nil) }
                case .recommended:
                    let source: WordBookSource = .recommended(id: identifier.id)
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

    private func loadRealmBook(id: String) -> Observable<WordBook?> {
        guard let objectId = try? ObjectId(string: id),
              let bookObject = wordBookRepo.read(id: objectId) else {
            return .just(nil)
        }
        let words = wordBookRepo.fetchWordsInWordBook(id: objectId)
        let wordBookStruct = WordBook(
            id: bookObject.id.stringValue,
            title: bookObject.title,
            wordList: words,
            createAt: bookObject.createAt
        )
        return .just(wordBookStruct)
    }
    
    // Helper: 추천 단어장 로드 (MockRepo에서 ID로 검색)
    private func loadRecommendedBook(id: String) -> Observable<WordBook?> {
        return recommendRepo.fetchRecommendBooks()
            .map { allBooks in
                allBooks.first(where: { $0.id == id })
            }
    }

    // '활성 단어장' 변경 (ViewControllers에서 호출)
    func setActiveBook(_ book: WordBook, source: WordBookSource) {
        
        if activeBook.value?.id != book.id {
            userInfo.clearQuizState()
        }
        
        let identifier: UserInfoManager.ActiveBookIdentifier
        
        switch source {
        case .realm(let id):
            identifier = .init(id: id, type: .realm)
//            userInfo.selectedBookId = id
        case .recommended(let id):
            identifier = .init(id: id, type: .recommended)
        }
        
        // 3. UserInfoManager의 식별자(영구 저장소)를 업데이트
        // -> 이 변경이 (1)번의 구독 로직을 트리거하여 activeBook이 자동 갱신됨
        userInfo.activeBookIdentifier = identifier
    }
    
    // 단어 삭제 시 인메모리 캐시 업데이트
//    func removeWordFromActiveBook(wordId: String) {
//        guard var currentBook = activeBook.value else { return }
//        currentBook.wordList.removeAll { $0.id == wordId }
//        activeBook.accept(currentBook) // 캐시된 객체 갱신
//    }
}
