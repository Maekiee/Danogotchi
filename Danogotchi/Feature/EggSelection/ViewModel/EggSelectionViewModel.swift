import Foundation
import RxSwift
import RxCocoa

final class EggSelectionViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private static let slotCount = 9

    struct Input {
        let itemSelected: Observable<EggItem>
        let nextTapped: Observable<Void>
    }

    struct Output {
        let eggItems: Driver<[EggItem]>
        let isNextEnabled: Driver<Bool>
        let didSelectEgg: Signal<PetType>
    }

    func transform(input: Input) -> Output {
        let types = PetType.allCases
        let selectedType = BehaviorRelay<PetType?>(value: nil)
        let didSelectEgg = PublishRelay<PetType>()

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
                    return EggItem(
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
