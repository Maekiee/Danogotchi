import Foundation
import OSLog
import RxSwift
import RxCocoa

final class SearchThemeViewModel: BaseViewModel {
    private static let networkErrorMessage = "잠시후 다시 시도해주세요"

    private let disposeBag = DisposeBag()
    private let searchThemeUseCase: SearchThemeUseCase
    private let saveThemeUseCase: SaveThemeUseCase

    init(
        searchThemeUseCase: SearchThemeUseCase,
        saveThemeUseCase: SaveThemeUseCase
    ) {
        self.searchThemeUseCase = searchThemeUseCase
        self.saveThemeUseCase = saveThemeUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let searchText: Observable<String>
        let loadNextPage: Observable<Void>
        let textEndTrigger: Observable<()>
        let selectedTheme: Observable<String?>
        let submitTapped: Observable<Void>
    }
    
    struct Output {
        let themeImageList: Driver<[ThemeImageViewData]>
        let buttonEnable: Driver<Bool>
        let alertMessage: Signal<String>
        let themeSaved: Signal<Void>
    }
    
    func transform(input: Input) -> Output {
        let imageItems = BehaviorRelay<[ThemeImageViewData]>(value: [])
        let nextPage = BehaviorRelay<Int>(value: 1)
        let totalImageCount = BehaviorRelay<Int>(value: 0)
        let currentSearchWord = BehaviorRelay<String>(value: "")
        let isLoading = BehaviorRelay<Bool>(value: false)
        
        let submitButtonIsHidden = BehaviorRelay<Bool>(value: true)
        let alertMessageRelay = PublishRelay<String>()
        let themeSavedRelay = PublishRelay<Void>()


        // 초기값
        input.viewWillAppear
            .take(1)
            .withLatestFrom(nextPage.asObservable())
            .flatMapLatest{ page in
                self.searchThemeUseCase.execute(query: "library", page: page)
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
                    AppLogger.network.error("테마 초기 로드 실패: \(String(describing: error), privacy: .public)")
                    CrashReporter.record(error)
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
                self.searchThemeUseCase.execute(query: searchWrod, page: page)
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
                    AppLogger.network.error("테마 페이지네이션 실패: \(String(describing: error), privacy: .public)")
                    CrashReporter.record(error)
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
                self.searchThemeUseCase.execute(query: text, page: 1)
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
                    AppLogger.network.error("테마 검색 실패: \(String(describing: error), privacy: .public)")
                    CrashReporter.record(error)
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

        input.submitTapped
            .withLatestFrom(input.selectedTheme)
            .compactMap { $0 }
            .bind(with: self) { owner, themeUrl in
                owner.saveThemeUseCase.execute(url: themeUrl)
                themeSavedRelay.accept(())
            }.disposed(by: disposeBag)

        return Output(
            themeImageList: imageItems.asDriver(onErrorJustReturn: []),
            buttonEnable: submitButtonIsHidden.asDriver(),
            alertMessage: alertMessageRelay.asSignal(),
            themeSaved: themeSavedRelay.asSignal()
        )
    }
}
