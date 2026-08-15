import Foundation
import RxSwift
import RxCocoa

final class OnboardingPetNameViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let createPetUseCase: CreatePetUseCase
    private let petType: PetType

    private static let tooLongMessage = "이름은 \(PetNamePolicy.maxLength)자까지 지을 수 있어요"
    private static let saveFailureMessage = "잠시 후 다시 시도해주세요"

    init(createPetUseCase: CreatePetUseCase, petType: PetType) {
        self.createPetUseCase = createPetUseCase
        self.petType = petType
    }

    struct Input {
        let nameText: Observable<String>
        let doneTapped: Observable<Void>
    }

    struct Output {
        /// nil이면 라벨이 비어 자리를 차지하지 않는다
        let errorMessage: Driver<String?>
        let isDoneEnabled: Driver<Bool>
        let didCreatePet: Signal<Void>
        let alertMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        let validation = BehaviorRelay<PetNameValidation>(value: .empty)
        let didCreatePet = PublishRelay<Void>()
        let alertMessage = PublishRelay<String>()

        // 입력은 막지 않는다 — 상한을 넘겨도 그대로 쓰이고 안내와 버튼 상태로만 알린다
        input.nameText
            .map { PetNamePolicy.validate($0) }
            .bind(to: validation)
            .disposed(by: disposeBag)

        // 아직 아무것도 안 쓴 상태(.empty)에는 안내를 띄우지 않는다
        let errorMessage = validation
            .map { result -> String? in
                guard case .tooLong = result else { return nil }
                return Self.tooLongMessage
            }

        let isDoneEnabled = validation
            .map { result -> Bool in
                guard case .valid = result else { return false }
                return true
            }

        input.doneTapped
            .withLatestFrom(validation)
            .compactMap { result -> String? in
                guard case .valid(let name) = result else { return nil }
                return name
            }
            .bind(with: self) { owner, name in
                guard owner.createPetUseCase.execute(type: owner.petType, name: name) != nil else {
                    alertMessage.accept(Self.saveFailureMessage)
                    return
                }

                didCreatePet.accept(())
            }.disposed(by: disposeBag)

        return Output(
            errorMessage: errorMessage.asDriver(onErrorJustReturn: nil),
            isDoneEnabled: isDoneEnabled.asDriver(onErrorJustReturn: false),
            didCreatePet: didCreatePet.asSignal(),
            alertMessage: alertMessage.asSignal()
        )
    }
}
