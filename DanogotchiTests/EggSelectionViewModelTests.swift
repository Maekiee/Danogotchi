import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class EggSelectionViewModelTests: XCTestCase {
    func test_initialGridHasNineSlotsWithOnlyRealTypesSelectable() {
        let screen = EggSelectionTestScreen()
        let items = screen.items

        XCTAssertEqual(items.count, 9)
        XCTAssertEqual(items.map(\.index), Array(0..<9))
        XCTAssertEqual(items.compactMap(\.petType), PetType.allCases)
        XCTAssertEqual(items.filter(\.isComingSoon).count, 9 - PetType.allCases.count)
        // 초기 상태(선택 nil)에서 준비중 칸이 선택된 것처럼 보이면 안 된다
        XCTAssertFalse(items.contains(where: \.isSelected))
        XCTAssertEqual(screen.isNextEnabled, false)
    }

    func test_comingSoonSlotCannotBeSelected() throws {
        let screen = EggSelectionTestScreen()
        let comingSoon = try XCTUnwrap(screen.items.first { $0.isComingSoon })

        screen.select.accept(comingSoon)
        screen.next.accept(())

        XCTAssertFalse(screen.items.contains(where: \.isSelected))
        XCTAssertEqual(screen.isNextEnabled, false)
        XCTAssertTrue(screen.selectedTypes.isEmpty)
    }

    func test_selectingEggMarksOnlyThatSlotAndEnablesNext() throws {
        let screen = EggSelectionTestScreen()
        let sprout = try XCTUnwrap(screen.items.first { $0.petType == .sprout })

        screen.select.accept(sprout)

        XCTAssertEqual(screen.items.filter(\.isSelected).map(\.petType), [.sprout])
        XCTAssertEqual(screen.isNextEnabled, true)
    }

    func test_nextEmitsSelectedTypeOnlyAfterSelection() throws {
        let screen = EggSelectionTestScreen()
        screen.next.accept(())
        XCTAssertTrue(screen.selectedTypes.isEmpty)

        screen.select.accept(try XCTUnwrap(screen.items.first { $0.petType == .sprout }))
        screen.next.accept(())
        XCTAssertEqual(screen.selectedTypes, [.sprout])
    }
}

@MainActor
private final class EggSelectionTestScreen {
    let select = PublishRelay<EggItem>()
    let next = PublishRelay<Void>()
    private(set) var items: [EggItem] = []
    private(set) var isNextEnabled: Bool?
    private(set) var selectedTypes: [PetType] = []
    private let viewModel = EggSelectionViewModel()
    private let bag = DisposeBag()

    init() {
        let output = viewModel.transform(input: .init(itemSelected: select.asObservable(), nextTapped: next.asObservable()))
        output.eggItems.drive(onNext: { [weak self] in self?.items = $0 }).disposed(by: bag)
        output.isNextEnabled.drive(onNext: { [weak self] in self?.isNextEnabled = $0 }).disposed(by: bag)
        output.didSelectEgg.emit(onNext: { [weak self] in self?.selectedTypes.append($0) }).disposed(by: bag)
    }
}
