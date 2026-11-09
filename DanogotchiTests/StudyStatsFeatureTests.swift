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
        let stats = makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _ in
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

    func test_appearedLoadsOnlyWhenStatsIsNil() async throws {
        let fetchCount = LockIsolated(0)
        let stats = makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _ in
                fetchCount.withValue { $0 += 1 }
                return stats
            }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, stats)) {
            $0.loadStatus = .idle
            $0.stats = stats
        }
        // 단어 목록에서 돌아와도 다시 읽지 않음
        await store.send(.appeared)
        XCTAssertEqual(fetchCount.value, 1)
    }

    func test_donutSelectionsIgnoreTouchEnd() async throws {
        let stats = makeStats()
        var state = StudyStatsFeature.State()
        state.stats = stats
        let store = TestStore(initialState: state) {
            StudyStatsFeature(fetch: { _, _ in stats }, reportError: { _ in }, onClose: {})
        }
        await store.send(.topicSelected("travel")) { $0.selectedTopic = "travel" }
        await store.send(.topicSelected(nil))
        await store.send(.partSelected("noun")) { $0.selectedPart = "noun" }
        await store.send(.partSelected(nil))
    }

    func test_refreshCancelsPreviousRequestAndIgnoresItsLateResponse() async throws {
        let attempts = LockIsolated(0)
        let errorCount = LockIsolated(0)
        let stats = makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _ in
                if attempts.withValue({ $0 += 1; return $0 }) == 1 {
                    do { try await Task.sleep(for: .seconds(3600)) } catch { throw CocoaError(.fileReadUnknown) }
                }
                return stats
            }, reportError: { _ in errorCount.withValue { $0 += 1 } }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.send(.refresh) { $0.loadStatus = .loading(self.secondID) }
        await store.receive(.loaded(secondID, stats)) {
            $0.loadStatus = .idle
            $0.stats = stats
        }
        await store.send(.loaded(firstID, stats))
        await store.finish()
        XCTAssertEqual(errorCount.value, 0)
    }

    func test_failedLoadRetriesAndCanLoadEmptyStats() async throws {
        let attempts = LockIsolated(0)
        let errors = LockIsolated<[NSError]>([])
        let stats = makeStats()
        let store = TestStore(initialState: StudyStatsFeature.State()) {
            StudyStatsFeature(fetch: { _, _ in
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

    func test_wordsTappedSendsAllWordsAndWordTappedFindsWordsOfEveryThreshold() async throws {
        let words = makeQuizWords(2)
        let rows = [makeQuizAnswer(words[0], createAt: statsDate(2026, 8, 1)).history,
                    makeQuizAnswer(words[0], createAt: statsDate()).history,
                    makeQuizAnswer(words[1], isCorrect: false, createAt: statsDate()).history]
        let stats = DefaultFetchStudyStatsUseCase.aggregate(.init(histories: rows, sessions: []),
                                                             now: statsDate(), calendar: statsCalendar())
        let destinations = LockIsolated<[StudyStatsDestination]>([])
        var state = StudyStatsFeature.State()
        state.stats = stats
        state.mistakeThreshold = .twenty
        let store = TestStore(initialState: state) {
            StudyStatsFeature(fetch: { _, _ in stats }, reportError: { _ in }, onClose: {},
                               onNavigate: { route in destinations.withValue { $0.append(route) } })
        }
        await store.send(.wordsTapped)
        await store.send(.wordTapped(words[1].id))
        await store.send(.wordTapped(words[0].id))
        await store.finish()
        guard case let .words(list) = destinations.value[0],
              case let .word(mistake, mistakeIsDaily) = destinations.value[1],
              case let .word(other, otherIsDaily) = destinations.value[2] else { return XCTFail("Expected routes") }
        XCTAssertEqual(list.start, statsCalendar().startOfDay(for: statsDate(2026, 8, 1)))
        XCTAssertEqual(list.end, statsDate())
        XCTAssertEqual(list.words, stats.words)
        XCTAssertTrue(StudyStatsMistakeThreshold.twenty.contains(mistake))
        XCTAssertEqual(mistake.id, words[1].id)
        XCTAssertEqual(other.id, words[0].id)
        XCTAssertEqual(other.total, 2)
        XCTAssertFalse(mistakeIsDaily)
        XCTAssertFalse(otherIsDaily)
    }

    func test_mistakeThresholdSurvivesReloadButDonutSelectionsReset() async throws {
        let stats = makeStats()
        var state = StudyStatsFeature.State()
        state.stats = stats
        state.selectedTopic = "travel"
        state.selectedPart = "noun"
        let store = TestStore(initialState: state) {
            StudyStatsFeature(fetch: { _, _ in stats }, reportError: { _ in }, onClose: {})
        } withDependencies: { $0.uuid = .incrementing }
        await store.send(.mistakeThresholdChanged(.forty)) { $0.mistakeThreshold = .forty }
        // 로딩 중엔 선택 유지, 새 통계 도착 시 도넛 선택만 초기화
        await store.send(.refresh) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, stats)) {
            $0.loadStatus = .idle
            $0.selectedTopic = nil
            $0.selectedPart = nil
        }
        XCTAssertEqual(StudyStatsFeature.State().mistakeThreshold, .seventy)
    }

    private func makeStats() -> StudyStats {
        DefaultFetchStudyStatsUseCase.aggregate(.init(histories: [], sessions: []),
                                                now: statsDate(), calendar: statsCalendar())
    }
}
