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
    }

    func transform(input: Input) -> Output {
        let bookItems = BehaviorRelay<[VocabBookCardInfo]>(value: [])

        // 상세에서 학습하기를 누르면 Library는 살아 있는 채로 갱신된다 — pop을 기다리지 않는다
        Observable.merge(
            input.viewWillAppear,
            fetchVocabBooksUseCase.activeBookChanged
        )
        .flatMapLatest { [weak self] _ -> Observable<[VocabBookCardInfo]> in
            guard let self else { return .empty() }
            return fetchVocabBooksUseCase.execute()
        }
        .bind(to: bookItems)
        .disposed(by: disposeBag)

        return Output(bookItems: bookItems.asDriver())
    }
}
