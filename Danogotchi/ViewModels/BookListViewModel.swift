import Foundation
import RxSwift
import RxCocoa

final class BookListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let recommendBookRepo = RecommendBookRepository()
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let recommendBooks: Driver<[WordBook]>
    }
    
    func transform(input: Input) -> Output {
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
        
        
        // 추천 단어장 불러오기
        viewWillAppear.flatMapLatest {
            return self.recommendBookRepo.fetchRecommendBooks()
        }.bind(with: self) { owner, books in
            recommendBookRelay.accept(books)
            print("단어장 불러옴")
        }.disposed(by: disposeBag)
        
        
        return Output(
            recommendBooks: recommendBookRelay.asDriver()
        )
    }
}
