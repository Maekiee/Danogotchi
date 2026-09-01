import Foundation
import OSLog
import RxSwift
import RxCocoa


final class CharacterViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()
    private let fetchPetStateUseCase: FetchPetStateUseCase
    private let carePetUseCase: CarePetUseCase
    private let levelUpPetUseCase: LevelUpPetUseCase
    private let adjustPetLevelUseCase: AdjustPetLevelUseCase
    private let revivePetUseCase: RevivePetUseCase
    private let fetchCurrentWeatherUseCase: FetchCurrentWeatherUseCase

    init(
        fetchPetStateUseCase: FetchPetStateUseCase,
        carePetUseCase: CarePetUseCase,
        levelUpPetUseCase: LevelUpPetUseCase,
        adjustPetLevelUseCase: AdjustPetLevelUseCase,
        revivePetUseCase: RevivePetUseCase,
        fetchCurrentWeatherUseCase: FetchCurrentWeatherUseCase
    ) {
        self.fetchPetStateUseCase = fetchPetStateUseCase
        self.carePetUseCase = carePetUseCase
        self.levelUpPetUseCase = levelUpPetUseCase
        self.adjustPetLevelUseCase = adjustPetLevelUseCase
        self.revivePetUseCase = revivePetUseCase
        self.fetchCurrentWeatherUseCase = fetchCurrentWeatherUseCase
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let didBecomeActive: Observable<Void>
        let careTapped: Observable<PetCareStat>
        let levelUpTapped: Observable<Void>
        let levelDeltaTapped: Observable<Int>
        let reviveTapped: Observable<Void>
    }

    struct Output {
        let info: Driver<PetDisplayInfo>
        let toastMessage: Signal<String>
        let weatherType: Driver<WeatherType>
    }

    func transform(input: Input) -> Output {
        let state = BehaviorRelay<PetDisplayInfo?>(value: nil)
        let toastMessage = PublishRelay<String>()
        let refreshTrigger = Observable.merge(input.viewWillAppear, input.didBecomeActive)
        let isWeatherLoading = BehaviorRelay<Bool>(value: false)
        let weatherType = BehaviorRelay<WeatherType?>(value: nil)
        
        refreshTrigger
            .bind(with: self) { owner, _ in
                state.accept(owner.fetchPetStateUseCase.execute())
            }.disposed(by: disposeBag)

        refreshTrigger
            .filter { !isWeatherLoading.value }
            .bind(with: self) { owner, _ in
                isWeatherLoading.accept(true)
                Task { @MainActor in
                    defer { isWeatherLoading.accept(false) }
                    do {
                        let weather = try await owner.fetchCurrentWeatherUseCase.getWeather()
                        weatherType.accept(weather.weatherType)
                        AppLogger.network.debug("현재 날씨 — 도시=\(weather.cityName, privacy: .public), 종류=\(String(describing: weather.weatherType), privacy: .public), 기온=\(weather.temperature, privacy: .public)℃, 체감=\(weather.feelsLike, privacy: .public)℃, 습도=\(weather.humidity, privacy: .public)%, 상태=\(weather.description, privacy: .public)")
                    } catch {
                        AppLogger.network.error("현재 날씨 조회 실패: \(String(describing: error), privacy: .public)")
                    }
                }
            }.disposed(by: disposeBag)

        input.careTapped
            .bind(with: self) { owner, stat in
                owner.apply(owner.carePetUseCase.execute(stat: stat), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        input.levelUpTapped
            .bind(with: self) { owner, _ in
                owner.apply(owner.levelUpPetUseCase.execute(), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        input.levelDeltaTapped
            .bind(with: self) { owner, delta in
                owner.apply(owner.adjustPetLevelUseCase.execute(delta: delta), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        input.reviveTapped
            .bind(with: self) { owner, _ in
                owner.apply(owner.revivePetUseCase.execute(), to: state, toast: toastMessage)
            }.disposed(by: disposeBag)

        return Output(
            info: state.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            toastMessage: toastMessage.asSignal(),
            weatherType: weatherType.compactMap { $0 }.asDriver(onErrorDriveWith: .empty())
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
