import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class BookListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    private let recommendBookRepo = RecommendBookRepository()
    private let wordBookRepo = WordBookRepository()
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let myBook: Driver<WordBook>
        let recommendBooks: Driver<[WordBook]>
    }
    
    func transform(input: Input) -> Output {
        let myBookRelay = PublishRelay<WordBook>()
        let recommendBookRelay = BehaviorRelay<[WordBook]>(value: [])
//        input.viewWillAppear
//            .flatMap {
//                let router = FirestoreRouter.fetchDocument(collection: Secret.firestoreCollectionName, documentId: Secret.firestoreDocId[0])
//                return FirestoreService.fetchDocument(router: router, type: FirestoreBookDTO.self).asObservable()
//            }.bind(with: self) { owner, res in
//                print(res)
//                print("----------------------------")
//                dump(res)
//            }.disposed(by: disposeBag)
        
        let viewWillAppear = input.viewWillAppear.take(1).share()
        
        
        // 내 단어장 불러오기
        viewWillAppear.bind(with: self) { owner, _ in
            if let wordBookId = owner.userInfo.selectedBookId,
               let bookId = try? ObjectId(string: wordBookId) {
            
                let book = owner.wordBookRepo.read(id: bookId).map {
                    return WordBook(
                        id: $0.id.stringValue,
                        title: $0.title,
                        wordList: [],
                        createAt: Date())
                }
                guard let myBook = book else { return }
                myBookRelay.accept(myBook)
            }
        }.disposed(by: disposeBag)
        
        // 추천 단어장 불러오기
        viewWillAppear.flatMapLatest {
            return self.recommendBookRepo.fetchRecommendBooks()
        }.bind(with: self) { owner, books in
            recommendBookRelay.accept(books)
            print("단어장 불러옴")
        }.disposed(by: disposeBag)
        
        
        return Output(
            myBook: myBookRelay.asDriver(onErrorDriveWith: .empty()),
            recommendBooks: recommendBookRelay.asDriver()
        )
    }
}
