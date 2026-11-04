import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable { }
    
    enum Action: Equatable {
        case historyButtonTapped
        case closeButtonTapped
    }
    
    let onClose: @MainActor @Sendable () -> Void
    let onNavigate: @MainActor @Sendable (StudyReportDestination) -> Void
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .historyButtonTapped:
                return .run { _ in await onNavigate(.history) }
            case .closeButtonTapped:
                return .run { _ in await onClose() }
            }
        }
    }
}
