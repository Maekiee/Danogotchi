import ComposableArchitecture
import Foundation

struct StudyReportWordList: Equatable, Sendable {
    let period: StudyReportPeriod
    let start: Date
    let end: Date
    let calendar: Calendar
    let words: [StudyReport.Word]
}

enum StudyReportDestination: Equatable, Sendable {
    case words(StudyReportWordList)
    case word(StudyReport.Word, StudyReportWordList)
}

@Reducer
struct StudyReportFeature {
    @ObservableState
    struct State: Equatable {
        var period: StudyReportPeriod = .week
        var report: StudyReport?
        var requestID: UUID?
        var hasError = false
        var selectedActivity: Date?
        var selectedSession: Int?
        var selectedTopic: String?
        var selectedPart: String?
        var selectedMistake: String?
        var mistakeKind: StudyReportCategoryKind = .topic

        var isLoading: Bool { requestID != nil }
    }

    enum Action: Equatable {
        case appeared
        case refresh
        case periodChanged(StudyReportPeriod)
        case loaded(UUID, StudyReport)
        case loadFailed(UUID)
        case activitySelected(Date?)
        case sessionSelected(Int?)
        case topicSelected(String?)
        case partSelected(String?)
        case mistakeSelected(String?)
        case mistakeKindChanged(StudyReportCategoryKind)
        case wordsTapped(StudyReportPeriod)
        case wordTapped(UUID)
        case closeButtonTapped
        case disappeared
    }

    private enum CancelID { case load }

    let fetch: @Sendable (StudyReportPeriod, Date, Calendar) async throws -> StudyReport
    let reportError: @Sendable (Error) -> Void
    let onClose: @MainActor @Sendable () -> Void
    var onNavigate: @MainActor @Sendable (StudyReportDestination) -> Void = { _ in }
    var now: @Sendable () -> Date = Date.init
    var calendar: @Sendable () -> Calendar = { Calendar.current }
    @Dependency(\.uuid) var uuid

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appeared:
                guard !state.isLoading, state.report == nil || state.report?.period != state.period else { return .none }
                return load(&state)
            case .refresh:
                return load(&state)
            case let .periodChanged(period):
                guard state.period != period else { return .none }
                state.period = period
                return load(&state)
            case let .loaded(id, report):
                guard state.requestID == id else { return .none }
                state.requestID = nil
                state.report = report
                state.hasError = false
                state.selectedActivity = report.hasActivity ? report.activity.last?.date : nil
                state.selectedSession = report.sessions.isEmpty ? nil : report.sessions.count - 1
                return .none
            case let .loadFailed(id):
                guard state.requestID == id else { return .none }
                state.requestID = nil
                state.hasError = true
                return .none
            case let .activitySelected(value):
                // 터치 종료(nil)·값 없는 차트는 기존 선택 유지
                guard let value, state.report?.hasActivity == true else { return .none }
                state.selectedActivity = value
                return .none
            case let .sessionSelected(value):
                // 터치 종료(nil)·범위 밖 회차는 기존 선택 유지
                guard let value, state.report?.sessions.indices.contains(value) == true else { return .none }
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
                guard let report = state.report, !state.isLoading, !state.hasError else { return .none }
                let list = wordList(report, period: period)
                return .run { _ in await onNavigate(.words(list)) }
            case let .wordTapped(id):
                guard let report = state.report, !state.isLoading, !state.hasError,
                      let word = report.words.first(where: { $0.id == id }) else { return .none }
                let list = wordList(report, period: state.period)
                return .run { _ in await onNavigate(.word(word, list)) }
            case .closeButtonTapped:
                state.requestID = nil
                return .concatenate(.cancel(id: CancelID.load), .run { _ in await onClose() })
            case .disappeared:
                state.requestID = nil
                return .cancel(id: CancelID.load)
            }
        }
    }

    private func load(_ state: inout State) -> Effect<Action> {
        let id = uuid()
        let period = state.period
        let date = now()
        let calendar = calendar()
        state.requestID = id
        state.hasError = false
        state.selectedActivity = nil
        state.selectedSession = nil
        state.selectedTopic = nil
        state.selectedPart = nil
        state.selectedMistake = nil
        return .run { send in
            do {
                let report = try await fetch(period, date, calendar)
                try Task.checkCancellation()
                await send(.loaded(id, report))
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

    private func wordList(_ report: StudyReport, period: StudyReportPeriod) -> StudyReportWordList {
        let start = period == .all
            ? report.allStart
            : report.periodStart
        return StudyReportWordList(
            period: period, start: start, end: report.now, calendar: report.calendar,
            words: period == .all ? report.allWords : report.words
        )
    }
}
