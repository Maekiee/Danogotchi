import ComposableArchitecture
import Foundation

struct StudyStatsWordList: Equatable, Sendable {
    let period: StudyStatsPeriod
    let start: Date
    let end: Date
    let calendar: Calendar
    let words: [VocabStats]
}

enum StudyStatsDestination: Equatable, Sendable {
    case stats
    case words(StudyStatsWordList)
    case word(VocabStats, StudyStatsWordList)
}

@Reducer
struct StudyStatsFeature {
    @ObservableState
    struct State: Equatable {
        enum LoadStatus: Equatable {
            case idle
            case loading(UUID)
            case failed
        }

        var period: StudyStatsPeriod = .week
        var stats: StudyStats?
        var loadStatus: LoadStatus = .idle
        var selectedActivity: Date?
        var selectedSession: Int?
        var selectedTopic: String?
        var selectedPart: String?
        var selectedMistake: String?
        var mistakeKind: StudyStatsCategoryKind = .topic

        var isLoading: Bool {
            if case .loading = loadStatus { return true }
            return false
        }
    }

    enum Action: Equatable {
        case appeared
        case refresh
        case periodChanged(StudyStatsPeriod)
        case loaded(UUID, StudyStats)
        case loadFailed(UUID)
        case activitySelected(Date?)
        case sessionSelected(Int?)
        case topicSelected(String?)
        case partSelected(String?)
        case mistakeSelected(String?)
        case mistakeKindChanged(StudyStatsCategoryKind)
        case wordsTapped(StudyStatsPeriod)
        case wordTapped(UUID)
        case closeButtonTapped
        case disappeared
    }

    private enum CancelID { case load }

    let fetch: @Sendable (StudyStatsPeriod, Date, Calendar) async throws -> StudyStats
    let reportError: @Sendable (Error) -> Void
    let onClose: @MainActor @Sendable () -> Void
    var onNavigate: @MainActor @Sendable (StudyStatsDestination) -> Void = { _ in }
    var now: @Sendable () -> Date = Date.init
    var calendar: @Sendable () -> Calendar = { Calendar.current }
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appeared:
                guard !state.isLoading, state.stats == nil || state.stats?.period != state.period else { return .none }
                return load(&state)
            case .refresh:
                return load(&state)
            case let .periodChanged(period):
                guard state.period != period else { return .none }
                state.period = period
                return load(&state)
            case let .loaded(id, stats):
                guard state.loadStatus == .loading(id) else { return .none }
                state.loadStatus = .idle
                state.stats = stats
                state.selectedActivity = stats.hasActivity ? stats.activity.last?.date : nil
                state.selectedSession = stats.sessions.isEmpty ? nil : stats.sessions.count - 1
                // 로딩 중엔 이전 선택 유지, 새 통계 도착 시 초기화
                state.selectedTopic = nil
                state.selectedPart = nil
                state.selectedMistake = nil
                return .none
            case let .loadFailed(id):
                guard state.loadStatus == .loading(id) else { return .none }
                state.loadStatus = .failed
                return .none
            case let .activitySelected(value):
                // 터치 종료(nil)·값 없는 차트는 기존 선택 유지
                guard let value, state.stats?.hasActivity == true else { return .none }
                state.selectedActivity = value
                return .none
            case let .sessionSelected(value):
                // 터치 종료(nil)·범위 밖 회차는 기존 선택 유지
                guard let value, state.stats?.sessions.indices.contains(value) == true else { return .none }
                state.selectedSession = value
                return .none
            case let .topicSelected(value):
                state.selectedTopic = value
                return .none
            case let .partSelected(value):
                // 터치 종료(nil)는 기존 선택 유지
                guard let value else { return .none }
                state.selectedPart = value
                return .none
            case let .mistakeSelected(value):
                state.selectedMistake = value
                return .none
            case let .mistakeKindChanged(value):
                state.mistakeKind = value
                state.selectedMistake = nil
                return .none
            case let .wordsTapped(period):
                guard let stats = state.stats, state.loadStatus == .idle else { return .none }
                let list = wordList(stats, period: period)
                return .run { _ in await onNavigate(.words(list)) }
            case let .wordTapped(id):
                guard let stats = state.stats, state.loadStatus == .idle,
                      let word = stats.words.first(where: { $0.id == id }) else { return .none }
                let list = wordList(stats, period: state.period)
                return .run { _ in await onNavigate(.word(word, list)) }
            case .closeButtonTapped:
                // 로딩만 취소, 오류 상태는 유지
                if state.isLoading { state.loadStatus = .idle }
                return .concatenate(.cancel(id: CancelID.load), .run { _ in await onClose() })
            case .disappeared:
                if state.isLoading { state.loadStatus = .idle }
                return .cancel(id: CancelID.load)
            }
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        let id = uuid()
        let period = state.period
        let date = now()
        let calendar = calendar()
        state.loadStatus = .loading(id)
        return .run { send in
            do {
                let stats = try await fetch(period, date, calendar)
                try Task.checkCancellation()
                await send(.loaded(id, stats))
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

    private func wordList(_ stats: StudyStats, period: StudyStatsPeriod) -> StudyStatsWordList {
        let start = period == .all
            ? stats.allStart
            : stats.periodStart
        return StudyStatsWordList(
            period: period, start: start, end: stats.now, calendar: stats.calendar,
            words: period == .all ? stats.allWords : stats.words
        )
    }
}
