import ComposableArchitecture
import XCTest
@testable import Danogotchi

@MainActor
final class CalendarFeatureTests: XCTestCase {
    private let firstID = UUID(0)
    private let today = statsDate(2026, 9, 26, 0)
    private let september = statsDate(2026, 9, 1, 0)
    private let words = makeQuizWords(2)

    func test_appearedLoadsCurrentMonthAndSelectsToday() async throws {
        let calendar = makeCalendar()
        let store = makeStore(fetch: { _, _ in calendar })
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, calendar)) {
            $0.loadStatus = .idle
            $0.calendar = calendar
            $0.displayedMonth = self.september
            $0.selectedDate = self.today
        }
        // 이미 읽었으면 다시 들어와도 읽지 않는다
        await store.send(.appeared)
    }

    // 범위는 2022년 1월(현재 연도 포함 5개 연도)~현재 달
    func test_monthMovesStayInRangeAndClearSelection() async throws {
        let store = makeStore(state: loadedState())
        await store.send(.monthMoved(1))
        await store.send(.monthMoved(-1)) {
            $0.displayedMonth = statsDate(2026, 8, 1, 0)
            $0.selectedDate = nil
        }
        await store.send(.monthPicked(statsDate(2022, 1, 1, 0))) { $0.displayedMonth = statsDate(2022, 1, 1, 0) }
        await store.send(.monthMoved(-1))
        await store.send(.monthPicked(statsDate(2021, 12, 1, 0)))
        await store.send(.monthPicked(statsDate(2026, 10, 1, 0)))
        await store.send(.monthPicked(statsDate(2026, 9, 15))) { $0.displayedMonth = self.september }
    }

    func test_emptyRecordsStillMoveToPastMonths() async throws {
        let empty = DefaultFetchCalendarUseCase.aggregate([], now: statsDate(), calendar: statsCalendar())
        let store = makeStore(state: CalendarFeature.State(calendar: empty, displayedMonth: september, selectedDate: today))
        await store.send(.monthMoved(-1)) {
            $0.displayedMonth = statsDate(2026, 8, 1, 0)
            $0.selectedDate = nil
        }
        await store.send(.todayTapped) {
            $0.displayedMonth = self.september
            $0.selectedDate = self.today
        }
    }

    func test_heatmapTapMovesMonthAndIgnoresFuture() async throws {
        let store = makeStore(state: loadedState())
        await store.send(.heatmapTapped(statsDate(2026, 7, 10, 14))) {
            $0.selectedDate = statsDate(2026, 7, 10, 0)
            $0.displayedMonth = statsDate(2026, 7, 1, 0)
        }
        await store.send(.heatmapTapped(statsDate(2026, 9, 27, 0)))
        // 첫 기록 달 이전 칸도 이동
        await store.send(.heatmapTapped(statsDate(2026, 6, 30))) {
            $0.selectedDate = statsDate(2026, 6, 30, 0)
            $0.displayedMonth = statsDate(2026, 6, 1, 0)
        }
    }

    func test_dateTapIgnoresFutureAndTodayReturnsToCurrentMonth() async throws {
        let store = makeStore(state: loadedState())
        await store.send(.dateTapped(statsDate(2026, 9, 27, 0)))
        await store.send(.dateTapped(statsDate(2026, 9, 24))) { $0.selectedDate = statsDate(2026, 9, 24, 0) }
        await store.send(.monthMoved(-2)) {
            $0.displayedMonth = statsDate(2026, 7, 1, 0)
            $0.selectedDate = nil
        }
        await store.send(.todayTapped) {
            $0.displayedMonth = self.september
            $0.selectedDate = self.today
        }
    }

    func test_dayChangeMovesTodaySelectionButKeepsOtherDates() async throws {
        let tomorrow = makeCalendar(now: statsDate(2026, 10, 1))
        let store = makeStore(state: loadedState(), fetch: { _, _ in tomorrow })
        await store.send(.refresh) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, tomorrow)) {
            $0.loadStatus = .idle
            $0.calendar = tomorrow
            $0.displayedMonth = statsDate(2026, 10, 1, 0)
            $0.selectedDate = statsDate(2026, 10, 1, 0)
        }

        var state = loadedState()
        state.selectedDate = statsDate(2026, 9, 24, 0)
        let other = makeStore(state: state, fetch: { _, _ in tomorrow })
        await other.send(.refresh) { $0.loadStatus = .loading(self.firstID) }
        await other.receive(.loaded(firstID, tomorrow)) {
            $0.loadStatus = .idle
            $0.calendar = tomorrow
        }
    }

    // 날짜 키가 새 시간대 자정이라 보던 날짜·달도 같은 날의 새 시간대 자정으로 옮긴다
    func test_timeZoneChangeKeepsViewedDayInNewTimeZone() async throws {
        let utc = statsCalendar("UTC")
        let moved = DefaultFetchCalendarUseCase.aggregate([], now: statsDate(), calendar: utc)
        var state = loadedState()
        state.selectedDate = statsDate(2026, 9, 24, 0)
        let store = makeStore(state: state, fetch: { _, _ in moved })
        await store.send(.refresh) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loaded(firstID, moved)) {
            $0.loadStatus = .idle
            $0.calendar = moved
            $0.selectedDate = statsDate(2026, 9, 24, 0, calendar: utc)
            $0.displayedMonth = statsDate(2026, 9, 1, 0, calendar: utc)
        }
    }

    func test_refreshFailureKeepsExistingCalendar() async throws {
        let errors = LockIsolated(0)
        let store = makeStore(state: loadedState(), fetch: { _, _ in throw CocoaError(.fileReadUnknown) },
                              reportError: { _ in errors.withValue { $0 += 1 } })
        await store.send(.refresh) { $0.loadStatus = .loading(self.firstID) }
        await store.receive(.loadFailed(firstID)) { $0.loadStatus = .failed }
        XCTAssertNotNil(store.state.calendar)
        XCTAssertEqual(errors.value, 1)
    }

    func test_disappearedCancelsLoadingAndStatsButtonWorksWhileLoading() async throws {
        let calendar = makeCalendar()
        let errors = LockIsolated(0)
        let destinations = LockIsolated<[StudyStatsDestination]>([])
        let store = makeStore(fetch: { _, _ in
            try await Task.sleep(for: .seconds(3600))
            return calendar
        }, reportError: { _ in errors.withValue { $0 += 1 } },
           onNavigate: { route in destinations.withValue { $0.append(route) } })
        await store.send(.appeared) { $0.loadStatus = .loading(self.firstID) }
        await store.send(.statsButtonTapped)
        await store.send(.disappeared) { $0.loadStatus = .idle }
        await store.finish()
        XCTAssertEqual(destinations.value, [.stats])
        XCTAssertEqual(errors.value, 0)
        XCTAssertNil(store.state.calendar)
    }

    func test_wordTappedOpensDailyDetailOfSelectedDate() async throws {
        let destinations = LockIsolated<[StudyStatsDestination]>([])
        var state = loadedState()
        state.selectedDate = statsDate(2026, 9, 24, 0)
        let store = makeStore(state: state, onNavigate: { route in destinations.withValue { $0.append(route) } })
        let word = try XCTUnwrap(state.calendar?.days[statsDate(2026, 9, 24, 0)]?.words.first)
        await store.send(.wordTapped(UUID()))
        await store.send(.wordTapped(word.id))
        await store.finish()
        XCTAssertEqual(destinations.value, [.word(word, isDaily: true)])
    }

    func test_closeButtonCallsOnCloseWithoutNavigating() async {
        let closeCount = LockIsolated(0)
        let destinations = LockIsolated<[StudyStatsDestination]>([])
        let store = makeStore(onClose: { closeCount.withValue { $0 += 1 } },
                              onNavigate: { route in destinations.withValue { $0.append(route) } })
        await store.send(.closeButtonTapped)
        await store.finish()
        XCTAssertEqual(closeCount.value, 1)
        XCTAssertTrue(destinations.value.isEmpty)
    }

    // 첫 기록 7월, 9월 24일 기록, 기준 시각 9월 26일 12시
    private func makeCalendar(now: Date = statsDate()) -> StudyCalendar {
        let rows = [makeQuizAnswer(words[0], createAt: statsDate(2026, 7, 10)).history,
                    makeQuizAnswer(words[1], isCorrect: false, createAt: statsDate(2026, 9, 24)).history]
        return DefaultFetchCalendarUseCase.aggregate(rows, now: now, calendar: statsCalendar())
    }

    private func loadedState() -> CalendarFeature.State {
        CalendarFeature.State(calendar: makeCalendar(), displayedMonth: september, selectedDate: today)
    }

    private func makeStore(
        state: CalendarFeature.State = CalendarFeature.State(),
        fetch: @escaping @Sendable (Date, Calendar) async throws -> StudyCalendar = { _, _ in throw CancellationError() },
        reportError: @escaping @Sendable (Error) -> Void = { _ in },
        onClose: @escaping @MainActor @Sendable () -> Void = {},
        onNavigate: @escaping @MainActor @Sendable (StudyStatsDestination) -> Void = { _ in }
    ) -> TestStoreOf<CalendarFeature> {
        TestStore(initialState: state) {
            CalendarFeature(fetch: fetch, reportError: reportError, onClose: onClose, onNavigate: onNavigate,
                            now: { statsDate() }, calendar: { statsCalendar() })
        } withDependencies: { $0.uuid = .incrementing }
    }
}
