import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable { }
    
    enum Action: Equatable {
        case statsButtonTapped
        case closeButtonTapped
    }
    
    let onClose: @MainActor @Sendable () -> Void
    let onNavigate: @MainActor @Sendable (StudyStatsDestination) -> Void
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .statsButtonTapped:
                return .run { _ in await onNavigate(.stats) }
            case .closeButtonTapped:
                return .run { _ in await onClose() }
            }
        }
    }
}
