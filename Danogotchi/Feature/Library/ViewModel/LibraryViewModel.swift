import Foundation
import RxSwift
import RxCocoa

final class LibraryViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabBooksUseCase: FetchVocabBooksUseCase

    init(fetchVocabBooksUseCase: FetchVocabBooksUseCase) {
        self.fetchVocabBooksUseCase = fetchVocabBooksUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
    }

    struct Output {
        let bookItems: Driver<[VocabBookCardInfo]>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        let bookItems = BehaviorRelay<[VocabBookCardInfo]>(value: [])
        let alertMessage = PublishRelay<String>()

        // 상세에서 학습하기를 누르면 Library는 살아 있는 채로 갱신된다 — pop을 기다리지 않는다
        Observable.merge(
            input.viewWillAppear,
            fetchVocabBooksUseCase.activeBookChanged
        )
        .flatMapLatest { [weak self] _ -> Observable<Result<[VocabBookCardInfo], Error>> in
            guard let self else { return .empty() }
            return fetchVocabBooksUseCase.execute()
        }
        .bind(onNext: { result in
            switch result {
            case .success(let items): bookItems.accept(items)
            case .failure: alertMessage.accept("단어장을 불러오지 못했어요. 다시 시도해주세요.")
            }
        })
        .disposed(by: disposeBag)

        return Output(bookItems: bookItems.asDriver(), alertMessage: alertMessage.asSignal())
    }
}
