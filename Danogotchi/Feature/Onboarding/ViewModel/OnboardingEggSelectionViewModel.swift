import Foundation
import RxSwift
import RxCocoa

final class OnboardingEggSelectionViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()

    /// 실제 알은 1종뿐이고, 9칸은 앞으로 늘어날 자리를 보여주는 UI 장치다.
    private static let slotCount = 9

    struct Input {
        let itemSelected: Observable<OnboardingEggItem>
        let nextTapped: Observable<Void>
    }

    struct Output {
        let eggItems: Driver<[OnboardingEggItem]>
        let isNextEnabled: Driver<Bool>
        let didSelectEgg: Signal<PetType>
    }

    func transform(input: Input) -> Output {
        let types = PetType.allCases
        let selectedType = BehaviorRelay<PetType?>(value: nil)
        let didSelectEgg = PublishRelay<PetType>()

        // 개발중 슬롯 탭은 compactMap에서 버려진다. 같은 알을 다시 눌러도 해제하지 않는다 —
        // 반드시 1개를 골라야 하므로 (관심사 화면과 동일)
        input.itemSelected
            .compactMap { $0.petType }
            .bind { type in
                selectedType.accept(type)
            }.disposed(by: disposeBag)

        let eggItems = selectedType
            .map { selected in
                (0..<Self.slotCount).map { index in
                    let type = index < types.count ? types[index] : nil
                    // type != nil 가드가 없으면 초기 상태(둘 다 nil)에서 개발중 8칸이 전부 선택돼 보인다
                    return OnboardingEggItem(
                        index: index,
                        petType: type,
                        isSelected: type != nil && type == selected
                    )
                }
            }

        input.nextTapped
            .withLatestFrom(selectedType)
            .compactMap { $0 }
            .bind(to: didSelectEgg)
            .disposed(by: disposeBag)

        return Output(
            eggItems: eggItems.asDriver(onErrorJustReturn: []),
            isNextEnabled: selectedType.map { $0 != nil }.asDriver(onErrorJustReturn: false),
            didSelectEgg: didSelectEgg.asSignal()
        )
    }
}
