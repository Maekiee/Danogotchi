import Foundation
import OSLog
import RxSwift
import RxCocoa

final class SearchThemeViewModel: BaseViewModel {
    private static let networkErrorMessage = "잠시후 다시 시도해주세요"

    private let disposeBag = DisposeBag()
    private let searchThemeUseCase: SearchThemeUseCase
    private let saveThemeUseCase: SaveThemeUseCase
    private var searchTask: Task<Void, Never>?

    init(
        searchThemeUseCase: SearchThemeUseCase,
        saveThemeUseCase: SaveThemeUseCase
    ) {
        self.searchThemeUseCase = searchThemeUseCase
        self.saveThemeUseCase = saveThemeUseCase
    }

    deinit {
        searchTask?.cancel()
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
        let isEmptyResult: Driver<Bool>
        let buttonEnable: Driver<Bool>
        let alertMessage: Signal<String>
        let themeSaved: Signal<Void>
        let isSaving: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let imageItems = BehaviorRelay<[ThemeImageViewData]>(value: [])
        let nextPage = BehaviorRelay<Int>(value: 1)
        let totalImageCount = BehaviorRelay<Int>(value: 0)
        let currentSearchWord = BehaviorRelay<String>(value: "")
        let isLoading = BehaviorRelay<Bool>(value: false)
        let isEmptyResult = BehaviorRelay<Bool>(value: false)
        
        let submitButtonIsHidden = BehaviorRelay<Bool>(value: true)
        let alertMessageRelay = PublishRelay<String>()
        let themeSavedRelay = PublishRelay<Void>()
        let isSaving = BehaviorRelay<Bool>(value: false)


        // 초기 조회, 검색, 페이지 요청을 하나의 Task로 관리한다.
        func loadPhotos(owner: SearchThemeViewModel, query: String, page: Int) {
            owner.searchTask?.cancel()
            isLoading.accept(true)

            if page == 1 {
                currentSearchWord.accept(query)
                nextPage.accept(1)
                totalImageCount.accept(0)
                imageItems.accept([])
                isEmptyResult.accept(false)
            }

            let useCase = owner.searchThemeUseCase
            // owner를 캡처하지 않아 요청 중에도 ViewModel이 해제될 수 있다.
            owner.searchTask = Task { @MainActor in
                defer {
                    // 이전 요청이 새 요청의 로딩 상태를 변경하지 않도록 한다.
                    if !Task.isCancelled { isLoading.accept(false) }
                }

                do {
                    let entity = try await useCase.execute(query: query, page: page)
                    try Task.checkCancellation()

                    let items = entity.results.map { ThemeImageViewData(from: $0) }
                    totalImageCount.accept(entity.total)
                    nextPage.accept(page + 1)
                    imageItems.accept(page == 1 ? items : imageItems.value + items)
                    isEmptyResult.accept(imageItems.value.isEmpty)
                } catch {
                    guard !Task.isCancelled, !(error is CancellationError) else { return }
                    isEmptyResult.accept(false)
                    AppLogger.network.error("테마 조회 실패(page=\(page)): \(String(describing: error), privacy: .public)")
                    CrashReporter.record(error)
                    alertMessageRelay.accept(Self.networkErrorMessage)
                }
            }
        }

        // 초기값
        input.viewWillAppear
            .take(1)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                loadPhotos(owner: owner, query: "library", page: 1)
            }.disposed(by: disposeBag)

        // 페이지네이션 — 요청 중에는 중복 호출을 무시한다.
        input.loadNextPage
            .observe(on: MainScheduler.instance)
            .filter { !isLoading.value && imageItems.value.count < totalImageCount.value }
            .bind(with: self) { owner, _ in
                loadPhotos(owner: owner, query: currentSearchWord.value, page: nextPage.value)
            }.disposed(by: disposeBag)

        // 검색 — 새 검색은 이전 조회 및 페이지 요청을 취소한다.
        input.textEndTrigger
            .withLatestFrom(input.searchText)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, text in
                loadPhotos(owner: owner, query: text, page: 1)
            }.disposed(by: disposeBag)

        input.selectedTheme
            .bind(with: self) { owner, selectedThemeUrl in
                if selectedThemeUrl != nil {
                    submitButtonIsHidden.accept(false)
                } else {
                    submitButtonIsHidden.accept(true)
                }
            }.disposed(by: disposeBag)

        // 이미지를 로컬에 내려받아 저장할 때까지 기다린다 — 저장에 실패하면 화면을 닫지 않는다
        input.submitTapped
            .withLatestFrom(input.selectedTheme)
            .compactMap { $0 }
            .filter { _ in !isSaving.value }
            .do(onNext: { _ in isSaving.accept(true) })
            .flatMapLatest { [saveThemeUseCase] rawUrl in
                saveThemeUseCase.execute(rawUrl: rawUrl)
            }
            .bind(with: self) { owner, result in
                isSaving.accept(false)
                switch result {
                case .success:
                    themeSavedRelay.accept(())
                case .failure(let error):
                    AppLogger.network.error("테마 이미지 저장 실패: \(String(describing: error), privacy: .public)")
                    CrashReporter.record(error)
                    alertMessageRelay.accept(Self.networkErrorMessage)
                }
            }.disposed(by: disposeBag)

        return Output(
            themeImageList: imageItems.asDriver(onErrorJustReturn: []),
            isEmptyResult: isEmptyResult.asDriver(),
            buttonEnable: submitButtonIsHidden.asDriver(),
            alertMessage: alertMessageRelay.asSignal(),
            themeSaved: themeSavedRelay.asSignal(),
            isSaving: isSaving.asDriver()
        )
    }
}
