import ComposableArchitecture

@Reducer
struct StudyReportFeature {
    @ObservableState
    struct State: Equatable { }

    enum Action {
        case closeButtonTapped
    }

    /// 닫기 "사실"만 위로 올린다 — dismiss는 Coordinator가 한다
    let onClose: @MainActor @Sendable () -> Void

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .closeButtonTapped:
                return .run { _ in await onClose() }
            }
        }
    }
}
