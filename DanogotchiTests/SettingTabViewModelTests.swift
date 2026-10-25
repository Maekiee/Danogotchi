import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class SettingTabViewModelTests: XCTestCase {
    func test_sectionsFollowCategoryOrderAndVersionComesFromEnvironment() {
        let screen = SettingTestScreen()
        XCTAssertEqual(screen.sections.map(\.category), SettingMenu.Category.allCases)
        XCTAssertEqual(screen.sections.map { $0.items.map(\.action) },
                       SettingMenu.Category.allCases.map { $0.list.map(\.action) })
        XCTAssertEqual(screen.appVersion, "v 1.2.3")
    }

    func test_reminderStateStartsFromUseCaseAndFollowsSuccessfulToggle() {
        let screen = SettingTestScreen(reminderEnabled: false)
        XCTAssertEqual(screen.isReminderOn, false)

        screen.toggle.accept(true)
        XCTAssertEqual(screen.isReminderOn, true)
        XCTAssertEqual(screen.reminder.setCalls, [true])
        XCTAssertTrue(screen.alerts.isEmpty)

        screen.toggle.accept(false)
        XCTAssertEqual(screen.isReminderOn, false)
    }

    func test_failedToggleAlertsAndRevertsToStoredValue() {
        let screen = SettingTestScreen(reminderEnabled: true)
        screen.reminder.failsSetEnabled = true

        screen.toggle.accept(false)

        XCTAssertEqual(screen.alerts, [String(localized: "알림 설정을 변경하지 못했어요. 다시 시도해주세요.")])
        // 스위치는 실제 저장값으로 되돌아간다
        XCTAssertEqual(screen.isReminderOn, true)
    }

    func test_selectingMenuEmitsActionAndOnlyInquiryBuildsMailBody() throws {
        let screen = SettingTestScreen()
        let inquiry = try XCTUnwrap(SettingMenu.Category.support.list.first { $0.action == .inquiry })
        let theme = try XCTUnwrap(SettingMenu.Category.general.list.first { $0.action == .searchTheme })

        screen.select.accept(theme)
        screen.select.accept(inquiry)

        XCTAssertEqual(screen.actions, [.searchTheme, .inquiry])
        XCTAssertEqual(screen.mailBodies.count, 1)
        let body = screen.mailBodies[0]
        XCTAssertTrue(body.contains("v 1.2.3"))
        XCTAssertTrue(body.contains("iPhone"))
        XCTAssertTrue(body.contains("26.0"))
    }
}

private struct TestAppEnvProvider: AppEnvProvider {
    let appVersion = "1.2.3"
    let appVersionDisplay = "v 1.2.3"
    let deviceModel = "iPhone"
    let systemVersion = "26.0"
}

private final class ControlledReminderUseCase: StudyReminderUseCase {
    var isEnabled: Bool
    var failsSetEnabled = false
    private(set) var setCalls: [Bool] = []

    init(isEnabled: Bool) { self.isEnabled = isEnabled }

    func setEnabled(_ isEnabled: Bool) throws {
        setCalls.append(isEnabled)
        if failsSetEnabled { throw CocoaError(.fileWriteOutOfSpace) }
        self.isEnabled = isEnabled
    }

    func refresh() throws {}
}

@MainActor
private final class SettingTestScreen {
    let reminder: ControlledReminderUseCase
    let select = PublishRelay<SettingMenu>()
    let toggle = PublishRelay<Bool>()
    private(set) var sections: [SettingTabViewModel.SettingSection] = []
    private(set) var appVersion = ""
    private(set) var isReminderOn: Bool?
    private(set) var actions: [SettingMenu.Action] = []
    private(set) var mailBodies: [String] = []
    private(set) var alerts: [String] = []
    private let viewModel: SettingTabViewModel
    private let bag = DisposeBag()

    init(reminderEnabled: Bool = true) {
        reminder = ControlledReminderUseCase(isEnabled: reminderEnabled)
        viewModel = SettingTabViewModel(appEnv: TestAppEnvProvider(), studyReminderUseCase: reminder)
        let output = viewModel.transform(input: .init(itemSelected: select.asObservable(), reminderToggled: toggle.asObservable()))
        output.sections.drive(onNext: { [weak self] in self?.sections = $0 }).disposed(by: bag)
        output.appVersion.drive(onNext: { [weak self] in self?.appVersion = $0 }).disposed(by: bag)
        output.isReminderOn.drive(onNext: { [weak self] in self?.isReminderOn = $0 }).disposed(by: bag)
        output.action.emit(onNext: { [weak self] in self?.actions.append($0) }).disposed(by: bag)
        output.mailBody.emit(onNext: { [weak self] in self?.mailBodies.append($0) }).disposed(by: bag)
        output.alertMessage.emit(onNext: { [weak self] in self?.alerts.append($0) }).disposed(by: bag)
    }
}
