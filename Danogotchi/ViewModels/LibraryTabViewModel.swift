import Foundation
import RxSwift
import RxCocoa


final class LibraryTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        
    }
    
    func transform(input: Input) -> Output {
        
        input.viewWillAppear
            .flatMap {
                let router = FirestoreRouter.fetchDocument(collection: Secret.firestoreCollectionName, documentId: Secret.firestoreDocId)
                return FirestoreService.fetchDocument(router: router, type: FirestoreBookDTO.self).asObservable()
            }.bind(with: self) { owner, res in
                print(res)
            }.disposed(by: disposeBag)
        
        
        
        return Output()
    }
    
}

