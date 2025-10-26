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
        let loadNextPage: Observable<Void>
        let textEndTrigger: Observable<()>
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
            .take(1)
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
                    totalImageCount.accept(entity.total)
                    nextPage.accept(2)
                    currentSearchWord.accept("library")
                case .failure(let error):
                    print("네트워크 통신 에러: \(error)")
                }
            }.disposed(by: disposeBag)
        
        input.loadNextPage
            .withLatestFrom(Observable.combineLatest(
                currentSearchWord.asObservable(),
                nextPage.asObservable(),
                imageItems.asObservable(),
                totalImageCount.asObservable(),
            ))
            .filter { (_, _, currentImages, total) in
                return currentImages.count < total && total > 0
            }.flatMapLatest { (searchWrod, page, _, Int) in
                self.repository.searchPhotos(query: searchWrod, page: page)
            }.bind(with: self) { owner, result in
                switch result {
                case .success(let entity):
                    let newViewDataList = entity.results.map { ThemeImageViewData(from: $0) }
                    var currentList = imageItems.value
                    currentList.append(contentsOf: newViewDataList)
                    imageItems.accept(currentList)
                    nextPage.accept(nextPage.value + 1)
                case .failure(let error):
                    print("무한 스크롤 로직 에러: \(error)")
                }
            }.disposed(by: disposeBag)
        
        
        
        return Output(
            themeImageList: imageItems.asDriver(onErrorJustReturn: [])
        )
    }
}
