import ComposableArchitecture
import XCTest
@testable import Danogotchi

@MainActor
final class StudyReportFeatureTests: XCTestCase {
    private let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    private let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func test_closeButtonTappedCallsOnCloseAndCancelsLoading() async throws {
        let closedCount = LockIsolated(0)
        let errorCount = LockIsolated(0)
        let report = try makeReport()
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(fetch: { _, _, _ in
                try await Task.sleep(for: .seconds(3600))
                return report
            }, reportError: { _ in errorCount.withValue { $0 += 1 } },
               onClose: { closedCount.withValue { $0 += 1 } })
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.requestID = self.firstID }
        await store.send(.closeButtonTapped) { $0.requestID = nil }
        await store.finish()
        XCTAssertEqual(closedCount.value, 1)
        XCTAssertEqual(errorCount.value, 0)
    }

    func test_loadPopulatesReportAndDefaultSelections() async throws {
        let report = try makeReport()
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(fetch: { _, _, _ in report }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.requestID = self.firstID }
        await store.receive(.loaded(firstID, report)) {
            $0.requestID = nil
            $0.report = report
        }
        // 막대 값이 모두 0이면 선택 문구를 띄우지 않음
        await store.send(.activitySelected(report.activity.last?.date))
        await store.send(.appeared)
    }

    func test_chartSelectionsDefaultToLatestAndIgnoreTouchEnd() async throws {
        let words = makeQuizWords(2)
        let answers = [makeQuizAnswer(words[0], createAt: reportDate(2026, 9, 24)),
                       makeQuizAnswer(words[1], isCorrect: false, createAt: reportDate())]
        let report = try DefaultFetchStudyReportUseCase.aggregate(
            .init(histories: answers.map(\.history), sessions: answers.map(\.session)),
            period: .week, now: reportDate(), calendar: reportCalendar()
        )
        let earlier = reportCalendar().startOfDay(for: reportDate(2026, 9, 24))
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(fetch: { _, _, _ in report }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.requestID = self.firstID }
        await store.receive(.loaded(firstID, report)) {
            $0.requestID = nil
            $0.report = report
            $0.selectedActivity = reportCalendar().startOfDay(for: reportDate())
            $0.selectedSession = 1
        }
        await store.send(.activitySelected(earlier)) { $0.selectedActivity = earlier }
        await store.send(.activitySelected(nil))
        await store.send(.sessionSelected(0)) { $0.selectedSession = 0 }
        await store.send(.sessionSelected(nil))
        await store.send(.sessionSelected(2))
        await store.send(.partSelected("noun")) { $0.selectedPart = "noun" }
        await store.send(.partSelected(nil))
    }

    func test_newPeriodCancelsPreviousRequestAndIgnoresItsLateResponse() async throws {
        let week = try makeReport()
        let month = try makeReport(.month)
        let errorCount = LockIsolated(0)
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(fetch: { period, _, _ in
                if period == .week {
                    do { try await Task.sleep(for: .seconds(3600)) }
                    catch { throw CocoaError(.fileReadUnknown) }
                }
                return month
            }, reportError: { _ in errorCount.withValue { $0 += 1 } }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.requestID = self.firstID }
        await store.send(.periodChanged(.month)) {
            $0.period = .month
            $0.requestID = self.secondID
        }
        await store.receive(.loaded(secondID, month)) {
            $0.requestID = nil
            $0.report = month
        }
        await store.send(.loaded(firstID, week))
        await store.finish()
        XCTAssertEqual(errorCount.value, 0)
    }

    func test_failedLoadRetriesAndCanLoadEmptyReport() async throws {
        let attempts = LockIsolated(0)
        let errors = LockIsolated<[NSError]>([])
        let report = try makeReport()
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(fetch: { _, _, _ in
                let attempt = attempts.withValue { $0 += 1; return $0 }
                if attempt == 1 { throw CocoaError(.fileReadUnknown) }
                return report
            }, reportError: { error in errors.withValue { $0.append(error as NSError) } }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.requestID = self.firstID }
        await store.receive(.loadFailed(firstID)) { $0.requestID = nil; $0.hasError = true }
        XCTAssertEqual(errors.value.map(\.domain), [NSCocoaErrorDomain])
        XCTAssertEqual(errors.value.map(\.code), [CocoaError.Code.fileReadUnknown.rawValue])
        await store.send(.refresh) { $0.requestID = self.secondID; $0.hasError = false }
        await store.receive(.loaded(secondID, report)) {
            $0.requestID = nil
            $0.report = report
        }
        XCTAssertEqual(store.state.report?.totalAnswers, 0)
        XCTAssertEqual(errors.value.count, 1)
    }

    func test_wordNavigationPreservesSelectedPeriodAndLifetimeUsesEarliestAnswer() async throws {
        let word = makeQuizWords(1)[0]
        let rows = [makeQuizAnswer(word, createAt: reportDate(2026, 8, 1)).history,
                    makeQuizAnswer(word, createAt: reportDate()).history]
        let report = try DefaultFetchStudyReportUseCase.aggregate(.init(histories: rows, sessions: []), period: .week,
                                                         now: reportDate(), calendar: reportCalendar())
        let destinations = LockIsolated<[StudyReportDestination]>([])
        var state = StudyReportFeature.State()
        state.report = report
        let store = TestStore(initialState: state) {
            StudyReportFeature(fetch: { _, _, _ in report }, reportError: { _ in }, onClose: {},
                               onNavigate: { route in destinations.withValue { $0.append(route) } })
        }
        await store.send(.wordsTapped(.all))
        await store.send(.wordsTapped(.week))
        await store.send(.wordTapped(word.id))
        await store.finish()
        guard case let .words(all) = destinations.value[0],
              case let .words(week) = destinations.value[1],
              case let .word(detail, scope) = destinations.value[2] else { return XCTFail("Expected routes") }
        XCTAssertEqual(all.start, report.allStart)
        XCTAssertEqual(all.words.first?.total, 2)
        XCTAssertEqual(week.period, .week)
        XCTAssertEqual(week.words.first?.total, 1)
        XCTAssertEqual(scope, week)
        XCTAssertEqual(detail.id, word.id)
    }

    func test_mistakeKindClearsSelectionAndPeriodClearsChartSelections() async throws {
        let report = try makeReport()
        var state = StudyReportFeature.State()
        state.report = report
        state.selectedActivity = report.activity.last?.date
        state.selectedTopic = "travel"
        state.selectedPart = "noun"
        state.selectedMistake = "travel"
        let store = TestStore(initialState: state) {
            StudyReportFeature(fetch: { _, _, _ in
                try await Task.sleep(for: .seconds(3600))
                return report
            }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.mistakeKindChanged(.partOfSpeech)) {
            $0.mistakeKind = .partOfSpeech
            $0.selectedMistake = nil
        }
        await store.send(.periodChanged(.all)) {
            $0.period = .all
            $0.requestID = self.firstID
            $0.selectedActivity = nil
            $0.selectedTopic = nil
            $0.selectedPart = nil
        }
        await store.send(.disappeared) { $0.requestID = nil }
        await store.finish()
    }

    private func makeReport(_ period: StudyReportPeriod = .week) throws -> StudyReport {
        try DefaultFetchStudyReportUseCase.aggregate(.init(histories: [], sessions: []), period: period,
                                             now: reportDate(), calendar: reportCalendar())
    }
}
