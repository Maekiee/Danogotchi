import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        enum LoadStatus: Equatable {
            case idle
            case loading(UUID)
            case failed
        }

        var calendar: StudyCalendar?
        // 첫 로드 때 현재 달·오늘로 채운다
        var displayedMonth: Date?
        var selectedDate: Date?
        var loadStatus: LoadStatus = .idle

        var isLoading: Bool {
            if case .loading = loadStatus { return true }
            return false
        }
    }

    enum Action: Equatable {
        case appeared
        case refresh
        case loaded(UUID, StudyCalendar)
        case loadFailed(UUID)
        case disappeared
        case monthMoved(Int)
        case monthPicked(Date)
        case todayTapped
        case dateTapped(Date)
        case heatmapTapped(Date)
        case wordTapped(UUID)
        case statsButtonTapped
        case closeButtonTapped
    }

    private enum CancelID { case load }

    let fetch: @Sendable (Date, Calendar) async throws -> StudyCalendar
    let reportError: @Sendable (Error) -> Void
    let onClose: @MainActor @Sendable () -> Void
    let onNavigate: @MainActor @Sendable (StudyStatsDestination) -> Void
    var now: @Sendable () -> Date = { Date() }
    var calendar: @Sendable () -> Calendar = { Calendar.current }
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appeared:
                guard !state.isLoading, state.calendar == nil else { return .none }
                return load(&state)
            case .refresh:
                return load(&state)
            case let .loaded(id, calendar):
                guard state.loadStatus == .loading(id) else { return .none }
                state.loadStatus = .idle
                // 첫 로드, 또는 오늘을 보던 중 날짜가 바뀌면 새 오늘로 옮긴다
                if state.calendar == nil || state.selectedDate == state.calendar?.today {
                    state.displayedMonth = calendar.currentMonth
                    state.selectedDate = calendar.today
                }
                state.calendar = calendar
                return .none
            case let .loadFailed(id):
                guard state.loadStatus == .loading(id) else { return .none }
                state.loadStatus = .failed
                return .none
            case .disappeared:
                if state.isLoading { state.loadStatus = .idle }
                return .cancel(id: CancelID.load)
            case let .monthMoved(offset):
                guard let calendar = state.calendar, let month = state.displayedMonth,
                      let target = calendar.calendar.date(byAdding: .month, value: offset, to: month) else { return .none }
                show(month: target, in: &state)
                return .none
            case let .monthPicked(month):
                show(month: month, in: &state)
                return .none
            case .todayTapped:
                guard let calendar = state.calendar else { return .none }
                state.displayedMonth = calendar.currentMonth
                state.selectedDate = calendar.today
                return .none
            case let .dateTapped(date):
                guard let calendar = state.calendar, date <= calendar.now else { return .none }
                state.selectedDate = calendar.calendar.startOfDay(for: date)
                return .none
            case let .heatmapTapped(date):
                // 첫 기록 달보다 앞선 칸은 달력이 갈 수 없어 무시
                guard let calendar = state.calendar, date <= calendar.now,
                      calendar.month(of: date) >= calendar.earliestMonth else { return .none }
                state.selectedDate = calendar.calendar.startOfDay(for: date)
                state.displayedMonth = calendar.month(of: date)
                return .none
            case let .wordTapped(id):
                guard let date = state.selectedDate,
                      let word = state.calendar?.days[date]?.words.first(where: { $0.id == id }) else { return .none }
                return .run { _ in await onNavigate(.word(word, isDaily: true)) }
            case .statsButtonTapped:
                return .run { _ in await onNavigate(.stats) }
            case .closeButtonTapped:
                if state.isLoading { state.loadStatus = .idle }
                return .concatenate(.cancel(id: CancelID.load), .run { _ in await onClose() })
            }
        }
    }

    // earliestMonth~현재 달 안에서만 이동, 이동하면 선택 해제
    private func show(month: Date, in state: inout State) {
        guard let calendar = state.calendar else { return }
        let month = calendar.month(of: month)
        guard month >= calendar.earliestMonth, month <= calendar.currentMonth else { return }
        state.displayedMonth = month
        state.selectedDate = nil
    }

    private func load(_ state: inout State) -> Effect<Action> {
        let id = uuid()
        let date = now()
        let calendar = calendar()
        state.loadStatus = .loading(id)
        return .run { send in
            do {
                let result = try await fetch(date, calendar)
                try Task.checkCancellation()
                await send(.loaded(id, result))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                reportError(error)
                await send(.loadFailed(id))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
