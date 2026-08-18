import Foundation
import RxSwift
import RxCocoa


final class CharacterViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()
    private let fetchPetStateUseCase: FetchPetStateUseCase
    private let carePetUseCase: CarePetUseCase
    private let levelUpPetUseCase: LevelUpPetUseCase
    private let revivePetUseCase: RevivePetUseCase

    init(
        fetchPetStateUseCase: FetchPetStateUseCase,
        carePetUseCase: CarePetUseCase,
        levelUpPetUseCase: LevelUpPetUseCase,
        revivePetUseCase: RevivePetUseCase
    ) {
        self.fetchPetStateUseCase = fetchPetStateUseCase
        self.carePetUseCase = carePetUseCase
        self.levelUpPetUseCase = levelUpPetUseCase
        self.revivePetUseCase = revivePetUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let didBecomeActive: Observable<Void>
        let careTapped: Observable<PetCareStat>
        let levelUpTapped: Observable<Void>
        /// 부활은 경험치를 깎으므로 확인 알럿을 통과한 뒤에 들어온다
        let reviveTapped: Observable<Void>
    }

    struct Output {
        /// 화면 전체를 한 번에 그린다 — 액션 결과가 여러 스트림으로 흩어지지 않게 한 덩어리로 둔다
        let info: Driver<PetDisplayInfo>
        let toastMessage: Signal<String>
    }

    func transform(input: Input) -> Output {
        // 온보딩이 펫 생성을 강제하므로 nil은 정상 경로에 없다. 화면은 그냥 흘려보낸다.
        let state = BehaviorRelay<PetDisplayInfo?>(value: nil)
        let toastMessage = PublishRelay<String>()

        // 조회가 곧 정산이다. 타이머 없이 진입과 포그라운드 복귀 두 시점에만 부른다.
        Observable.merge(input.viewWillAppear, input.didBecomeActive)
            .bind(with: self) { owner, _ in
                state.accept(owner.fetchPetStateUseCase.execute())
            }.disposed(by: disposeBag)

        input.careTapped
            .bind(with: self) { owner, stat in
                owner.apply(owner.carePetUseCase.execute(stat: stat), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        input.levelUpTapped
            .bind(with: self) { owner, _ in
                owner.apply(owner.levelUpPetUseCase.execute(), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        input.reviveTapped
            .bind(with: self) { owner, _ in
                owner.apply(owner.revivePetUseCase.execute(), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        return Output(
            info: state.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            toastMessage: toastMessage.asSignal()
        )
    }

    /// 거절 여부와 무관하게 항상 다시 그린다 — UseCase가 어느 결과든 정산분을 저장하기 때문이다.
    private func apply(
        _ result: PetActionResult?,
        to state: BehaviorRelay<PetDisplayInfo?>,
        toast: PublishRelay<String>
    ) {
        guard let result else { return }

        state.accept(result.info)

        if let rejection = result.rejection {
            toast.accept(Self.message(for: rejection))
        }
    }

    private static func message(for rejection: PetActionRejection) -> String {
        switch rejection {
        case .alreadyFull:
            return "이미 충분해요"
        case .dead:
            return "먼저 부활시켜 주세요"
        case .notEnoughExperience:
            return "경험치가 부족해요"
        case .alive:
            return "아직 건강해요"
        }
    }
}
