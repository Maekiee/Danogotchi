import Foundation
import RxSwift
import RxCocoa

final class SearchThemeViewModel: BaseViewModel {
    private static let networkErrorMessage = "잠시후 다시 시도해주세요"

    private let disposeBag = DisposeBag()
    private let repository: SearchThemeRepository
    private let mode: SearchThemeViewController.EntryMode
//    private let mode: SearchThemeViewController.EntryMode

    init(
        mode: SearchThemeViewController.EntryMode,
        repository: SearchThemeRepository
    ) {
        self.repository = repository
        self.mode = mode
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let searchText: Observable<String>
        let loadNextPage: Observable<Void>
        let textEndTrigger: Observable<()>
        let selectedTheme: Observable<String?>
    }
    
    struct Output {
        let themeImageList: Driver<[ThemeImageViewData]>
        let buttonEnable: Driver<Bool>
        let alertMessage: Signal<String>
    }
    
    func transform(input: Input) -> Output {
        let imageItems = BehaviorRelay<[ThemeImageViewData]>(value: [])
        let nextPage = BehaviorRelay<Int>(value: 1)
        let totalImageCount = BehaviorRelay<Int>(value: 0)
        let currentSearchWord = BehaviorRelay<String>(value: "")
        let isLoading = BehaviorRelay<Bool>(value: false)
        
        let submitButtonIsHidden = BehaviorRelay<Bool>(value: true)
        let alertMessageRelay = PublishRelay<String>()


        // 초기값
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
                    alertMessageRelay.accept(Self.networkErrorMessage)
                }
            }.disposed(by: disposeBag)
        
        
        // 페이지 네이션
        input.loadNextPage
            .withLatestFrom(Observable.combineLatest(
                currentSearchWord.asObservable(),
                nextPage.asObservable(),
                imageItems.asObservable(),
                totalImageCount.asObservable(),
            ))
            .filter { (_, _, currentImages, total) in
                return currentImages.count < total && total > 0
            }
            // 진행 중인 요청이 있으면 무시한다 (중복 요청 · 반복 알럿 방지)
            .filter { _ in !isLoading.value }
            .do(onNext: { _ in isLoading.accept(true) })
            .flatMapLatest { (searchWrod, page, _, Int) in
                self.repository.searchPhotos(query: searchWrod, page: page)
            }.bind(with: self) { owner, result in
                isLoading.accept(false)
                switch result {
                case .success(let entity):
                    let newViewDataList = entity.results.map { ThemeImageViewData(from: $0) }
                    var currentList = imageItems.value
                    currentList.append(contentsOf: newViewDataList)
                    imageItems.accept(currentList)
                    nextPage.accept(nextPage.value + 1)
                case .failure(let error):
                    print("무한 스크롤 로직 에러: \(error)")
                    alertMessageRelay.accept(Self.networkErrorMessage)
                }
            }.disposed(by: disposeBag)
        
        
        // 검색
        input.textEndTrigger
            .withLatestFrom(input.searchText)
            .distinctUntilChanged()
            .do { text in
                currentSearchWord.accept(text)
            }
            .flatMap { text in
                self.repository.searchPhotos(query: text, page: 1)
            }
            .bind(with: self) { owner, result in
                imageItems.accept([])
                switch result {
                case .success(let entity):
                    let viewDataList = entity.results.map {
                        ThemeImageViewData(from: $0)
                    }
                    imageItems.accept(viewDataList)
                    totalImageCount.accept(entity.total)
                    nextPage.accept(2)
                case .failure(let error):
                    print("검색 에러 \(error)")
                    alertMessageRelay.accept(Self.networkErrorMessage)
                }
            }.disposed(by: disposeBag)
        
        input.selectedTheme
            .bind(with: self) { owner, selectedThemeUrl in
                if selectedThemeUrl != nil {
                    submitButtonIsHidden.accept(false)
                } else {
                    submitButtonIsHidden.accept(true)
                }
            }.disposed(by: disposeBag)
        
        
        
        
        return Output(
            themeImageList: imageItems.asDriver(onErrorJustReturn: []),
            buttonEnable: submitButtonIsHidden.asDriver(),
            alertMessage: alertMessageRelay.asSignal()
        )
    }
}
