import Foundation
import RxSwift
import RxCocoa

final class OnboardingInterestViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let selectInterestUseCase: SelectInterestUseCase
    private var downloadTask: Task<Void, Never>?

    init(selectInterestUseCase: SelectInterestUseCase) {
        self.selectInterestUseCase = selectInterestUseCase
    }

    deinit {
        downloadTask?.cancel()
    }

    struct Input {
        let topicSelected: Observable<BookTopic>
        let nextTapped: Observable<Void>
    }

    struct Output {
        let interestItems: Driver<[OnboardingInterestItem]>
        let isNextEnabled: Driver<Bool>
        /// 고른 주제의 단어장을 받는 중
        let isLoading: Driver<Bool>
        let didFinish: Signal<Void>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        // 나의 단어장은 관심사가 아니다 — 분기는 항상 bookType 기준
        let topics = BookTopic.allCases.filter { $0 != .myBook }
        let selectedTopic = BehaviorRelay<BookTopic?>(value: nil)
        let isLoading = BehaviorRelay<Bool>(value: false)
        let didFinish = PublishRelay<Void>()
        let alertMessage = PublishRelay<String>()

        // 같은 카드를 다시 눌러도 선택은 유지된다(해제 없음) — 반드시 1개를 골라야 하므로
        input.topicSelected
            // 받는 중에는 선택을 바꾸지 않는다 — 표시된 주제와 저장되는 주제가 같도록
            .filter { _ in !isLoading.value }
            .bind { topic in
                selectedTopic.accept(topic)
            }.disposed(by: disposeBag)

        let interestItems = selectedTopic
            .map { selected in
                topics.map { OnboardingInterestItem(topic: $0, isSelected: $0 == selected) }
            }

        // 고른 주제의 A1을 받아 학습중으로 둔 뒤에만 다음 단계로 간다. 실패하면 머물고 다음을 다시 누르면 재시도
        input.nextTapped
            .withLatestFrom(selectedTopic)
            .compactMap { $0 }
            .filter { _ in !isLoading.value }
            .bind(with: self) { owner, topic in
                // 로딩 표시를 동기로 켜 중복 요청을 막는다
                isLoading.accept(true)
                let useCase = owner.selectInterestUseCase
                // owner를 캡처하지 않아 요청 중에도 ViewModel이 해제될 수 있다.
                owner.downloadTask = Task { @MainActor in
                    do {
                        try await useCase.execute(topic: topic)
                        isLoading.accept(false)
                        didFinish.accept(())
                    } catch {
                        guard !Task.isCancelled else { return }
                        isLoading.accept(false)
                        alertMessage.accept(String(localized: "단어장을 받지 못했어요. 네트워크 연결을 확인하고 다시 시도해주세요."))
                    }
                }
            }
            .disposed(by: disposeBag)

        return Output(
            interestItems: interestItems.asDriver(onErrorJustReturn: []),
            isNextEnabled: Observable.combineLatest(selectedTopic, isLoading) { $0 != nil && !$1 }
                .asDriver(onErrorJustReturn: false),
            isLoading: isLoading.asDriver(),
            didFinish: didFinish.asSignal(),
            alertMessage: alertMessage.asSignal()
        )
    }
}
