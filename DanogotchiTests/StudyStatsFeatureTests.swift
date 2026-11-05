import ComposableArchitecture
import XCTest
@testable import Danogotchi

@MainActor
final class StudyStatsFeatureTests: XCTestCase {
    private let firstID = UUID(0)
    private let secondID = UUID(1)

    func test_closeButtonTappedCallsOnCloseAndCancelsLoading() async throws {
        let closedCount = LockIsolated(0)
        let errorCount = LockIsolated(0)
        let stats = try makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _, _ in
                try await Task.sleep(for: .seconds(3600))
                return stats
            }, reportError: { _ in errorCount.withValue { $0 += 1 } },
               onClose: { closedCount.withValue { $0 += 1 } })
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.send(.closeButtonTapped) { $0.loadStatus = .idle }
        await store.finish()
        XCTAssertEqual(closedCount.value, 1)
        XCTAssertEqual(errorCount.value, 0)
    }

    func test_loadPopulatesStatsAndDefaultSelections() async throws {
        let stats = try makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _, _ in stats }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, stats)) {
            $0.loadStatus = .idle
            $0.stats = stats
        }
        // 막대 값이 모두 0이면 선택 문구를 띄우지 않음
        await store.send(.activitySelected(stats.activity.last?.date))
        await store.send(.appeared)
    }

    func test_chartSelectionsDefaultToLatestAndIgnoreTouchEnd() async throws {
        let words = makeQuizWords(2)
        let answers = [makeQuizAnswer(words[0], createAt: statsDate(2026, 9, 24)),
                       makeQuizAnswer(words[1], isCorrect: false, createAt: statsDate())]
        let stats = try DefaultFetchStudyStatsUseCase.aggregate(
            .init(histories: answers.map(\.history), sessions: answers.map(\.session)),
            period: .week, now: statsDate(), calendar: statsCalendar()
        )
        let earlier = statsCalendar().startOfDay(for: statsDate(2026, 9, 24))
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _, _ in stats }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, stats)) {
            $0.loadStatus = .idle
            $0.stats = stats
            $0.selectedActivity = statsCalendar().startOfDay(for: statsDate())
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
        let week = try makeStats()
        let month = try makeStats(.month)
        let errorCount = LockIsolated(0)
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { period, _, _ in
                if period == .week {
                    do { try await Task.sleep(for: .seconds(3600)) }
                    catch { throw CocoaError(.fileReadUnknown) }
                }
                return month
            }, reportError: { _ in errorCount.withValue { $0 += 1 } }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.send(.periodChanged(.month)) {
            $0.period = .month
            $0.loadStatus = .loading(self.secondID)
        }
        await store.receive(.loaded(secondID, month)) {
            $0.loadStatus = .idle
            $0.stats = month
        }
        await store.send(.loaded(firstID, week))
        await store.finish()
        XCTAssertEqual(errorCount.value, 0)
    }

    func test_failedLoadRetriesAndCanLoadEmptyStats() async throws {
        let attempts = LockIsolated(0)
        let errors = LockIsolated<[NSError]>([])
        let stats = try makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _, _ in
                let attempt = attempts.withValue { $0 += 1; return $0 }
                if attempt == 1 { throw CocoaError(.fileReadUnknown) }
                return stats
            }, reportError: { error in errors.withValue { $0.append(error as NSError) } }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loadFailed(firstID)) { $0.loadStatus = .failed }
        await store.send(.disappeared)
        XCTAssertEqual(errors.value.map(\.domain), [NSCocoaErrorDomain])
        XCTAssertEqual(errors.value.map(\.code), [CocoaError.Code.fileReadUnknown.rawValue])
        await store.send(.refresh) { $0.loadStatus = .loading(self.secondID) }
        await store.receive(.loaded(secondID, stats)) {
            $0.loadStatus = .idle
            $0.stats = stats
        }
        XCTAssertEqual(store.state.stats?.totalAnswers, 0)
        XCTAssertEqual(errors.value.count, 1)
    }

    func test_wordNavigationPreservesSelectedPeriodAndLifetimeUsesEarliestAnswer() async throws {
        let word = makeQuizWords(1)[0]
        let rows = [makeQuizAnswer(word, createAt: statsDate(2026, 8, 1)).history,
                    makeQuizAnswer(word, createAt: statsDate()).history]
        let stats = try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []), period: .week,
                                                         now: statsDate(), calendar: statsCalendar())
        let destinations = LockIsolated<[StudyStatsDestination]>([])
        var state = StudyStatsFeature.State()
        state.stats = stats
        let store = TestStore(initialState: state) {
            StudyStatsFeature(fetch: { _, _, _ in stats }, reportError: { _ in }, onClose: {},
                               onNavigate: { route in destinations.withValue { $0.append(route) } })
        }
        await store.send(.wordsTapped(.all))
        await store.send(.wordsTapped(.week))
        await store.send(.wordTapped(word.id))
        await store.finish()
        guard case let .words(all) = destinations.value[0],
              case let .words(week) = destinations.value[1],
              case let .word(detail, scope) = destinations.value[2] else { return XCTFail("Expected routes") }
        XCTAssertEqual(all.start, stats.allStart)
        XCTAssertEqual(all.words.first?.total, 2)
        XCTAssertEqual(week.period, .week)
        XCTAssertEqual(week.words.first?.total, 1)
        XCTAssertEqual(scope, week)
        XCTAssertEqual(detail.id, word.id)
    }

    func test_mistakeKindClearsSelectionAndPeriodClearsChartSelections() async throws {
        let stats = try makeStats()
        var state = StudyStatsFeature.State()
        state.stats = stats
        state.selectedActivity = stats.activity.last?.date
        state.selectedTopic = "travel"
        state.selectedPart = "noun"
        state.selectedMistake = "travel"
        let store = TestStore(initialState: state) {
            StudyStatsFeature(fetch: { _, _, _ in stats }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.mistakeKindChanged(.partOfSpeech)) {
            $0.mistakeKind = .partOfSpeech
            $0.selectedMistake = nil
        }
        // 로딩 중엔 선택 유지, 새 통계 도착 시 초기화
        await store.send(.periodChanged(.all)) {
            $0.period = .all
            $0.loadStatus = .loading(self.firstID)
        }
        await store.receive(.loaded(firstID, stats)) {
            $0.loadStatus = .idle
            $0.selectedActivity = nil
            $0.selectedTopic = nil
            $0.selectedPart = nil
        }
        await store.finish()
    }

    private func makeStats(_ period: StudyStatsPeriod = .week) throws -> StudyStats {
        try DefaultFetchStudyStatsUseCase.aggregate(.init(histories: [], sessions: []), period: period,
                                             now: statsDate(), calendar: statsCalendar())
    }
}
