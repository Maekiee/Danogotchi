import Foundation
import OSLog
import RxSwift
import RxCocoa

final class LibraryViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabBooksUseCase: FetchVocabBooksUseCase
    private var remoteBooksTask: Task<Void, Never>?

    init(fetchVocabBooksUseCase: FetchVocabBooksUseCase) {
        self.fetchVocabBooksUseCase = fetchVocabBooksUseCase
    }

    deinit {
        remoteBooksTask?.cancel()
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
        // 받은 서버 목록을 보관한다 — 다시 나타날 때마다 읽으면 읽기 과금이 늘어난다. nil이면 아직 못 받았다
        let remoteBooks = BehaviorRelay<[RemoteVocabBook]?>(value: nil)
        let isFetchingRemoteBooks = BehaviorRelay<Bool>(value: false)

        // 상세에서 학습하기를 누르면 Library는 살아 있는 채로 갱신된다 — pop을 기다리지 않는다
        let activeBookChanged = Observable.onMain { [fetchVocabBooksUseCase] in fetchVocabBooksUseCase.activeBookChanged }

        // 받은 단어장은 즉시 보여주고, 서버 목록이 도착하면 합쳐 다시 그린다
        Observable.merge(
            input.viewWillAppear,
            activeBookChanged,
            remoteBooks.skip(1).map { _ in }
        )
        .bind(with: self) { owner, _ in
            do {
                bookItems.accept(try owner.fetchVocabBooksUseCase.execute(remoteBooks: remoteBooks.value ?? []))
            } catch {
                alertMessage.accept(String(localized: "단어장을 불러오지 못했어요. 다시 시도해주세요."))
            }
        }
        .disposed(by: disposeBag)

        // 못 받았으면 다시 나타날 때 다시 받는다 — 받는 중이면 겹쳐 읽지 않는다
        input.viewWillAppear
            .filter { remoteBooks.value == nil && !isFetchingRemoteBooks.value }
            .bind(with: self) { owner, _ in
                isFetchingRemoteBooks.accept(true)
                let useCase = owner.fetchVocabBooksUseCase
                // owner를 캡처하지 않아 요청 중에도 ViewModel이 해제될 수 있다.
                owner.remoteBooksTask = Task { @MainActor in
                    defer { isFetchingRemoteBooks.accept(false) }
                    do {
                        let books = try await useCase.fetchRemoteBooks()
                        guard !Task.isCancelled else { return }
                        remoteBooks.accept(books)
                    } catch {
                        // 알림 없이 받은 단어장만 보여준다
                        AppLogger.network.error("서버 단어장 목록 조회 실패: \(String(describing: error), privacy: .public)")
                    }
                }
            }
            .disposed(by: disposeBag)

        return Output(bookItems: bookItems.asDriver(), alertMessage: alertMessage.asSignal())
    }
}
