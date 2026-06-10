import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class LibraryViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let activeManager = ActiveLearningManager.shared
    
    private let recommendBookRepository: RecommendBookRepository
    private let wordBookRepository: WordBookRepository
    private let wordRepository: WordRepository
    
    init (
        recommendBookRepository: RecommendBookRepository,
        wordBookRepository: WordBookRepository,
        wordRepository: WordRepository
    ) {
        self.recommendBookRepository = recommendBookRepository
        self.wordBookRepository = wordBookRepository
        self.wordRepository = wordRepository
    }
    
    let downloadBookTrigger = PublishRelay<WordBook>()
    
    enum RecommendItem: Hashable {
        case downloaded(WordBook)
        case notDownloaded(WordBook)
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let myBook: Driver<WordBook?>
        let recommendItems: Driver<[RecommendItem]>
        let downloadComplete: Signal<Void>
        let isLoading: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let myBookRelay = BehaviorRelay<WordBook?>(value: nil)
        let recommendItemsRelay = BehaviorRelay<[RecommendItem]>(value: [])
        let downloadCompleteRelay = PublishRelay<Void>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        
        let refreshTrigger = Observable.merge(
            input.viewWillAppear,
            downloadCompleteRelay.asObservable()
        ).startWith(())
        
        refreshTrigger.bind(with: self) { owner, _ in
            guard let myBookStruct = owner.wordBookRepository.readAll().first(where: { $0.title == "나의 단어장" }) else {
                myBookRelay.accept(nil)
                return
            }
            
            myBookRelay.accept(myBookStruct)
            
        }.disposed(by: disposeBag)
        
        
        
        refreshTrigger
            .flatMapLatest { [weak self] _ -> Observable<[RecommendItem]> in
                guard let self = self else { return .just([]) }
                
                let myBooks = self.wordBookRepository.readAll()
                
                return self.recommendBookRepository.fetchRecommendBooks()
                    .map { mockBooks in
                        mockBooks.map { mockBook in
                            if let matchingRealmBook = myBooks.first(where: { $0.title == mockBook.title }) {
                                if matchingRealmBook.title == "나의 단어장" {
                                    return nil
                                } else {
                                    return .downloaded(matchingRealmBook)
                                }
                            } else {
                                return .notDownloaded(mockBook)
                            }
                        }
                        .compactMap { $0 }
                    }
            }
            .bind(to: recommendItemsRelay)
            .disposed(by: disposeBag)
        
        downloadBookTrigger
            .bind(with: self) { owner, bookToCopy in
                isLoadingRelay.accept(true)
                
                
                DispatchQueue.main.async {
                    let allMyBooks = owner.wordBookRepository.readAll()
                    if allMyBooks.contains(where: { $0.title == bookToCopy.title }) {
                        DispatchQueue.main.async {
                            ToastManager.shared.show("이미 '내 단어장'에 존재합니다.")
                            isLoadingRelay.accept(false)
                            downloadCompleteRelay.accept(())
                        }
                        return
                    }
                    
                    owner.wordBookRepository.create(title: bookToCopy.title)
                    
                    guard let newBookObject = owner.wordBookRepository.readAll().last(where: {
                        $0.title == bookToCopy.title })?.toObject() else {
                        DispatchQueue.main.async {
                            isLoadingRelay.accept(false)
                        }
                        return
                    }
                    
                    for word in bookToCopy.wordList {
                        let newWordObject = owner.wordRepository.create(
                            thumbnail: "",
                            word: word.word,
                            meaning: word.meaning
                        )
                        
                        owner.wordBookRepository.addWord(bookId: newBookObject.id, word: newWordObject)
                    }
                    
                    ToastManager.shared.show("'\(bookToCopy.title)' 단어장이 추가되었습니다.")
                    isLoadingRelay.accept(false)
                    downloadCompleteRelay.accept(())
                }
            }.disposed(by: disposeBag)
        
        
        return Output(
            myBook: myBookRelay.asDriver(),
            recommendItems: recommendItemsRelay.asDriver(),
            downloadComplete: downloadCompleteRelay.asSignal(),
            isLoading: isLoadingRelay.asDriver()
        )
    }
}
