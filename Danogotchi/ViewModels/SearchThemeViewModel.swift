import Foundation
import RxSwift
import RxCocoa

final class SearchThemeViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let repository: SearchThemeRepoProtocol
    
    init(repository: SearchThemeRepoProtocol = SearchThemeRepository()) {
        self.repository = repository
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let searchText: Observable<String>
    }
    
    struct Output {
        let themeImageList: Driver<[ThemeImageViewData]>
    }
    
    func transform(input: Input) -> Output {
        let imageItems = BehaviorRelay<[ThemeImageViewData]>(value: [])
        let nextPage = BehaviorRelay<Int>(value: 1)
        let totalImageCount = BehaviorRelay<Int>(value: 0)
        let currentSearchWord = BehaviorRelay<String>(value: "")
        let isLoading = BehaviorRelay<Bool>(value: false)
        
        input.viewWillAppear
            .withLatestFrom(nextPage.asObservable())
            .flatMapLatest{ page in
                self.repository.searchPhotos(query: "library", page: page)
            }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let entity):
                    let viewDataList = entity.results.map { photoEntity in
                        ThemeImageViewData(from: photoEntity)
                    }
                    imageItems.accept(viewDataList)
                case .failure(let error):
                    print("네트워크 통신 에러: \(error)")
                }
            }.disposed(by: disposeBag)
        
        
        
        return Output(
            themeImageList: imageItems.asDriver(onErrorJustReturn: [])
        )
    }
}
