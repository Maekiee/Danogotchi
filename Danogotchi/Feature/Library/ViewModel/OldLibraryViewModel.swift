import Foundation
import RxSwift
import RxCocoa

final class OldLibraryViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let activeManager = ActiveLearningManager.shared
    
    private let recommendBookRepository: RecommendBookRepository
    private let vocabBookRepository: VocabBookRepository

    init(
        recommendBookRepository: RecommendBookRepository,
        vocabBookRepository: VocabBookRepository
    ) {
        self.recommendBookRepository = recommendBookRepository
        self.vocabBookRepository = vocabBookRepository
    }
    
    let downloadBookTrigger = PublishRelay<VocabBook>()
    
    enum RecommendItem: Hashable {
        case downloaded(VocabBook)
        case notDownloaded(VocabBook)
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let myBook: Driver<VocabBook?>
        let recommendItems: Driver<[RecommendItem]>
        let downloadComplete: Signal<Void>
        let isLoading: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let myBookRelay = BehaviorRelay<VocabBook?>(value: nil)
        let recommendItemsRelay = BehaviorRelay<[RecommendItem]>(value: [])
        let downloadCompleteRelay = PublishRelay<Void>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        
        let refreshTrigger = Observable.merge(
            input.viewWillAppear,
            downloadCompleteRelay.asObservable()
        ).startWith(())
        
        refreshTrigger.bind(with: self) { owner, _ in
            guard let myBook = owner.vocabBookRepository.readAllBooks(type: .mine).first else {
                myBookRelay.accept(nil)
                return
            }

            myBookRelay.accept(myBook)

        }.disposed(by: disposeBag)
        
        
        
        refreshTrigger
            .flatMapLatest { [weak self] _ -> Observable<[RecommendItem]> in
                guard let self = self else { return .just([]) }

                let downloadedBooks = self.vocabBookRepository.readAllBooks(type: .recommended)

                return self.recommendBookRepository.fetchRecommendBooks()
                    .map { recommendBooks in
                        recommendBooks.map { recommendBook in
                            if let downloadedBook = downloadedBooks.first(where: {
                                $0.originBookId == recommendBook.originBookId
                            }) {
                                return .downloaded(downloadedBook)
                            } else {
                                return .notDownloaded(recommendBook)
                            }
                        }
                    }
            }
            .bind(to: recommendItemsRelay)
            .disposed(by: disposeBag)
        
        downloadBookTrigger
            .bind(with: self) { owner, bookToCopy in
                isLoadingRelay.accept(true)
                
                
                DispatchQueue.main.async {
                    let downloadedBooks = owner.vocabBookRepository.readAllBooks(type: .recommended)
                    if downloadedBooks.contains(where: { $0.originBookId == bookToCopy.originBookId }) {
                        ToastManager.shared.show("이미 '내 단어장'에 존재합니다.")
                        isLoadingRelay.accept(false)
                        downloadCompleteRelay.accept(())
                        return
                    }

                    let newBook = owner.vocabBookRepository.createBook(
                        title: bookToCopy.title,
                        type: .recommended,
                        originBookId: bookToCopy.originBookId
                    )

                    for vocab in bookToCopy.vocabList {
                        _ = owner.vocabBookRepository.addVocab(
                            bookId: newBook.id,
                            word: vocab.word,
                            meaning: vocab.meaning,
                            originWordId: vocab.id.uuidString
                        )
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
