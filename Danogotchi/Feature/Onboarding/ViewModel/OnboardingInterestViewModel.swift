import Foundation
import RxSwift
import RxCocoa

final class OnboardingInterestViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let setActiveBookUseCase: SetActiveBookUseCase

    init(setActiveBookUseCase: SetActiveBookUseCase) {
        self.setActiveBookUseCase = setActiveBookUseCase
    }

    struct Input {
        let topicSelected: Observable<BookTopic>
        let nextTapped: Observable<Void>
    }

    struct Output {
        let interestItems: Driver<[OnboardingInterestItem]>
        let isNextEnabled: Driver<Bool>
        let didFinish: Signal<Void>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        // 나의 단어장은 관심사가 아니다 — 분기는 항상 bookType 기준
        let topics = BookTopic.allCases.filter { $0 != .myBook }
        let selectedTopic = BehaviorRelay<BookTopic?>(value: nil)
        let didFinish = PublishRelay<Void>()
        let alertMessage = PublishRelay<String>()

        // 같은 카드를 다시 눌러도 선택은 유지된다(해제 없음) — 반드시 1개를 골라야 하므로
        input.topicSelected
            .bind { topic in
                selectedTopic.accept(topic)
            }.disposed(by: disposeBag)

        let interestItems = selectedTopic
            .map { selected in
                topics.map { OnboardingInterestItem(topic: $0, isSelected: $0 == selected) }
            }

        input.nextTapped
            .withLatestFrom(selectedTopic)
            .compactMap { $0 }
            .flatMapLatest { [weak self] topic -> Observable<Result<Bool, Error>> in
                guard let self else { return .empty() }
                return setActiveBookUseCase.execute(topic: topic)
            }
            .bind(onNext: { result in
                switch result {
                case .success(true): didFinish.accept(())
                case .success(false), .failure:
                    alertMessage.accept("저장하지 못했어요. 다시 시도해주세요.")
                }
            })
            .disposed(by: disposeBag)

        return Output(
            interestItems: interestItems.asDriver(onErrorJustReturn: []),
            isNextEnabled: selectedTopic.map { $0 != nil }.asDriver(onErrorJustReturn: false),
            didFinish: didFinish.asSignal(),
            alertMessage: alertMessage.asSignal()
        )
    }
}
