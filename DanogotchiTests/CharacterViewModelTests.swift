import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class CharacterViewModelTests: XCTestCase {
    func test_appearLoadsSettledPetInfoWithoutToast() throws {
        let screen = try CharacterTestScreen(pet: makePet(satiety: 50, stateUpdatedAt: Date()))
        screen.appear.accept(())
        XCTAssertEqual(screen.infos.count, 1)
        XCTAssertEqual(screen.infos.last?.pet.name, "테스트")
        XCTAssertEqual(screen.infos.last?.pet.satiety ?? 0, 50, accuracy: 0.01)
        XCTAssertEqual(screen.infos.last?.mood, .hungry)
        XCTAssertTrue(screen.toasts.isEmpty)
    }

    func test_missingPetEmitsNothing() throws {
        let screen = try CharacterTestScreen(pet: nil)
        screen.appear.accept(())
        screen.care.accept(.satiety)
        screen.levelUp.accept(())
        screen.levelDelta.accept(1)
        screen.revive.accept(())
        XCTAssertTrue(screen.infos.isEmpty)
        XCTAssertTrue(screen.toasts.isEmpty)
    }

    func test_loadFailureShowsToastAndKeepsPreviousInfo() throws {
        let screen = try CharacterTestScreen(pet: makePet(stateUpdatedAt: Date()))
        screen.appear.accept(())
        // 조회가 곧 정산 저장이므로 저장 실패가 조회 실패다
        screen.context.failsSave = true
        screen.becomeActive.accept(())
        XCTAssertEqual(screen.infos.count, 1)
        XCTAssertEqual(screen.toasts, [String(localized: "상태를 불러오지 못했어요. 다시 시도해주세요.")])
    }

    func test_careRecoversStatAndPersistsWithoutToast() throws {
        let screen = try CharacterTestScreen(pet: makePet(satiety: 50, stateUpdatedAt: Date()))
        screen.care.accept(.satiety)
        XCTAssertEqual(screen.infos.last?.pet.satiety ?? 0, 75, accuracy: 0.01)
        XCTAssertTrue(screen.toasts.isEmpty)
        XCTAssertEqual(try screen.repository.readPet()?.satiety ?? 0, 75, accuracy: 0.01)
    }

    func test_rejectionsStillRedrawAndExplainWhy() throws {
        let full = try CharacterTestScreen(pet: makePet(satiety: 100, stateUpdatedAt: Date()))
        full.care.accept(.satiety)
        XCTAssertEqual(full.infos.count, 1)
        XCTAssertEqual(full.toasts, [String(localized: "이미 충분해요")])

        let dead = try CharacterTestScreen(pet: makePet(satiety: 50, hp: 0, stateUpdatedAt: Date()))
        dead.care.accept(.satiety)
        XCTAssertEqual(dead.infos.last?.pet.satiety ?? 0, 50, accuracy: 0.01)
        XCTAssertEqual(dead.toasts, [String(localized: "먼저 부활시켜 주세요")])

        let poor = try CharacterTestScreen(pet: makePet(level: 2, experience: 0, stateUpdatedAt: Date()))
        poor.levelUp.accept(())
        XCTAssertEqual(poor.infos.last?.pet.level, 2)
        XCTAssertEqual(poor.toasts, [String(localized: "경험치가 부족해요")])

        let alive = try CharacterTestScreen(pet: makePet(stateUpdatedAt: Date()))
        alive.revive.accept(())
        XCTAssertEqual(alive.infos.count, 1)
        XCTAssertEqual(alive.toasts, [String(localized: "아직 건강해요")])
    }

    func test_levelUpAndReviveApplyWhenAllowed() throws {
        let ready = try CharacterTestScreen(pet: makePet(level: 0, experience: 1_000, stateUpdatedAt: Date()))
        ready.levelUp.accept(())
        XCTAssertEqual(ready.infos.last?.pet.level, 1)
        XCTAssertEqual(ready.infos.last?.pet.experience, 0)
        XCTAssertTrue(ready.toasts.isEmpty)

        let dead = try CharacterTestScreen(pet: makePet(satiety: 0, hydration: 0, fun: 0, cleanliness: 0, hp: 0,
                                                        stateUpdatedAt: Date()))
        dead.revive.accept(())
        XCTAssertEqual(dead.infos.last?.pet.hp ?? 0, PetStatePolicy.maxHP, accuracy: 0.01)
        XCTAssertEqual(dead.infos.last?.pet.satiety ?? 0, PetStatePolicy.reviveFloor, accuracy: 0.01)
        XCTAssertTrue(dead.toasts.isEmpty)
    }

    func test_levelDeltaMovesLevelWithinBounds() throws {
        let screen = try CharacterTestScreen(pet: makePet(level: 0, stateUpdatedAt: Date()))
        screen.levelDelta.accept(-1)
        XCTAssertEqual(screen.infos.last?.pet.level, 0)
        screen.levelDelta.accept(1)
        XCTAssertEqual(screen.infos.last?.pet.level, 1)
        screen.levelDelta.accept(PetLevelPolicy.maxLevel + 5)
        XCTAssertEqual(screen.infos.last?.pet.level, PetLevelPolicy.maxLevel)
        XCTAssertTrue(screen.toasts.isEmpty)
    }

    func test_saveFailureShowsToastAndLeavesStoredPetUntouched() throws {
        let screen = try CharacterTestScreen(pet: makePet(satiety: 50, stateUpdatedAt: Date()))
        screen.context.failsSave = true
        screen.care.accept(.satiety)
        XCTAssertTrue(screen.infos.isEmpty)
        XCTAssertEqual(screen.toasts, [String(localized: "저장하지 못했어요. 다시 시도해주세요.")])
        XCTAssertEqual(try screen.repository.readPet()?.satiety ?? 0, 50, accuracy: 0.01)
    }

    func test_weatherLoadsOncePerRefreshAndIgnoresReentryWhileLoading() async throws {
        let screen = try CharacterTestScreen(pet: nil)
        let requested = expectation(description: "weather requested")
        screen.weather.onCall = { requested.fulfill() }
        screen.appear.accept(())
        // 응답 전 재진입은 새 요청을 만들지 않는다
        screen.becomeActive.accept(())
        await fulfillment(of: [requested], timeout: 2)
        XCTAssertEqual(screen.weather.calls, 1)

        let delivered = expectation(description: "weather delivered")
        screen.onWeather = { _ in delivered.fulfill() }
        screen.weather.resume(with: .success(makeWeather(.rain)))
        await fulfillment(of: [delivered], timeout: 2)
        XCTAssertEqual(screen.weathers, [.rain])

        let again = expectation(description: "second request after completion")
        screen.weather.onCall = { again.fulfill() }
        screen.becomeActive.accept(())
        await fulfillment(of: [again], timeout: 2)
        XCTAssertEqual(screen.weather.calls, 2)
    }

    func test_weatherFailureEmitsNothingAndNextRefreshRetries() async throws {
        let screen = try CharacterTestScreen(pet: nil)
        let requested = expectation(description: "weather requested")
        screen.weather.onCall = { requested.fulfill() }
        screen.appear.accept(())
        await fulfillment(of: [requested], timeout: 2)

        screen.weather.onCall = nil
        screen.weather.resume(with: .failure(URLError(.timedOut)))
        // 실패 처리가 끝나면 다음 진입에서 다시 요청한다
        let retried = await eventually {
            screen.becomeActive.accept(())
            return screen.weather.calls == 2
        }
        XCTAssertTrue(retried)
        XCTAssertTrue(screen.weathers.isEmpty)
    }

    private func eventually(_ condition: @MainActor () -> Bool, timeout: TimeInterval = 2) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }
}

private func makeWeather(_ type: WeatherType) -> CurrentWeather {
    CurrentWeather(cityName: "Seoul", temperature: 20, feelsLike: 19, humidity: 50,
                   weatherType: type, description: "", iconCode: "")
}

@MainActor
private final class ControlledWeatherUseCase: FetchCurrentWeatherUseCase {
    private(set) var calls = 0
    var onCall: (() -> Void)?
    private var pending: [CheckedContinuation<CurrentWeather, Error>] = []

    func getWeather() async throws -> CurrentWeather {
        calls += 1
        onCall?()
        return try await withCheckedThrowingContinuation { pending.append($0) }
    }

    func resume(with result: Result<CurrentWeather, Error>) {
        let waiting = pending
        pending.removeAll()
        waiting.forEach { $0.resume(with: result) }
    }
}

/// 펫 유스케이스는 실제 구현을 인메모리 저장소에 올리고, 날씨만 제어 가능한 가짜로 둔다
@MainActor
private final class CharacterTestScreen {
    let context: FailingSaveContext
    let repository: DefaultPetRepository
    let weather = ControlledWeatherUseCase()
    let appear = PublishRelay<Void>()
    let becomeActive = PublishRelay<Void>()
    let care = PublishRelay<PetCareStat>()
    let levelUp = PublishRelay<Void>()
    let levelDelta = PublishRelay<Int>()
    let revive = PublishRelay<Void>()
    private(set) var infos: [PetDisplayInfo] = []
    private(set) var toasts: [String] = []
    private(set) var weathers: [WeatherType] = []
    var onWeather: ((WeatherType) -> Void)?
    private let viewModel: CharacterViewModel
    private let bag = DisposeBag()

    init(pet: Pet?) throws {
        context = makeFailingSaveContext()
        repository = DefaultPetRepository(context: context)
        if let pet { _ = try repository.createPet(pet) }
        viewModel = CharacterViewModel(
            fetchPetStateUseCase: DefaultFetchPetStateUseCase(petRepository: repository),
            carePetUseCase: DefaultCarePetUseCase(petRepository: repository),
            levelUpPetUseCase: DefaultLevelUpPetUseCase(petRepository: repository),
            adjustPetLevelUseCase: DefaultAdjustPetLevelUseCase(petRepository: repository),
            revivePetUseCase: DefaultRevivePetUseCase(petRepository: repository),
            fetchCurrentWeatherUseCase: weather
        )
        let output = viewModel.transform(input: .init(
            viewWillAppear: appear.asObservable(),
            didBecomeActive: becomeActive.asObservable(),
            careTapped: care.asObservable(),
            levelUpTapped: levelUp.asObservable(),
            levelDeltaTapped: levelDelta.asObservable(),
            reviveTapped: revive.asObservable()
        ))
        output.info.drive(onNext: { [weak self] in self?.infos.append($0) }).disposed(by: bag)
        output.toastMessage.emit(onNext: { [weak self] in self?.toasts.append($0) }).disposed(by: bag)
        output.weatherType.drive(onNext: { [weak self] type in
            self?.weathers.append(type)
            self?.onWeather?(type)
        }).disposed(by: bag)
    }
}
