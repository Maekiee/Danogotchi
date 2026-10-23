import CoreData
import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class OnboardingPetNameViewModelTests: XCTestCase {
    func test_emptyInputShowsNoGuidanceAndLocksDone() {
        let screen = PetNameTestScreen()
        screen.name.accept("   ")
        XCTAssertEqual(screen.errors, [nil, nil])
        XCTAssertEqual(screen.isDoneEnabled, false)
    }

    func test_tooLongNameShowsLimitAndLocksDone() {
        let screen = PetNameTestScreen()
        screen.name.accept(String(repeating: "가", count: PetNamePolicy.maxLength + 1))
        XCTAssertEqual(screen.errors.last, String(localized: "이름은 \(PetNamePolicy.maxLength)자까지 지을 수 있어요"))
        XCTAssertEqual(screen.isDoneEnabled, false)

        // 상한으로 줄이면 안내가 사라지고 버튼이 열린다
        screen.name.accept(String(repeating: "가", count: PetNamePolicy.maxLength))
        XCTAssertNil(screen.errors.last ?? nil)
        XCTAssertEqual(screen.isDoneEnabled, true)
    }

    func test_doneCreatesPetWithTrimmedNameAndNotifies() throws {
        let screen = PetNameTestScreen()
        screen.name.accept("  새싹이 ")
        screen.done.accept(())

        XCTAssertEqual(screen.created, 1)
        XCTAssertTrue(screen.alerts.isEmpty)
        let pet = try XCTUnwrap(screen.repository.readPet())
        XCTAssertEqual(pet.name, "새싹이")
        XCTAssertEqual(pet.type, .sprout)
        XCTAssertEqual(pet.satiety, PetStatePolicy.initialStat)
    }

    func test_doneWithInvalidNameDoesNothing() throws {
        let screen = PetNameTestScreen()
        screen.done.accept(())
        screen.name.accept(String(repeating: "a", count: PetNamePolicy.maxLength + 1))
        screen.done.accept(())

        XCTAssertEqual(screen.created, 0)
        XCTAssertNil(try screen.repository.readPet())
    }

    func test_saveFailureAlertsAndSameInputCanRetry() throws {
        let screen = PetNameTestScreen()
        screen.name.accept("새싹이")
        screen.context.failsSave = true
        screen.done.accept(())
        XCTAssertEqual(screen.created, 0)
        XCTAssertEqual(screen.alerts, [String(localized: "잠시 후 다시 시도해주세요")])
        XCTAssertNil(try screen.repository.readPet())

        screen.context.failsSave = false
        screen.done.accept(())
        XCTAssertEqual(screen.created, 1)
        XCTAssertEqual(try screen.repository.readPet()?.name, "새싹이")
    }
}

@MainActor
private final class PetNameTestScreen {
    let context = makeFailingSaveContext()
    let repository: DefaultPetRepository
    let name = PublishRelay<String>()
    let done = PublishRelay<Void>()
    private(set) var errors: [String?] = []
    private(set) var isDoneEnabled: Bool?
    private(set) var created = 0
    private(set) var alerts: [String] = []
    private let viewModel: OnboardingPetNameViewModel
    private let bag = DisposeBag()

    init() {
        repository = DefaultPetRepository(context: context)
        viewModel = OnboardingPetNameViewModel(createPetUseCase: DefaultCreatePetUseCase(petRepository: repository),
                                               petType: .sprout)
        let output = viewModel.transform(input: .init(nameText: name.asObservable(), doneTapped: done.asObservable()))
        output.errorMessage.drive(onNext: { [weak self] in self?.errors.append($0) }).disposed(by: bag)
        output.isDoneEnabled.drive(onNext: { [weak self] in self?.isDoneEnabled = $0 }).disposed(by: bag)
        output.didCreatePet.emit(onNext: { [weak self] in self?.created += 1 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
