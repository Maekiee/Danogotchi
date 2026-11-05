import ComposableArchitecture
import SwiftUI

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>
    var body: some View {
        Text("calendar view")
            .navigationTitle("캘린더")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { store.send(.closeButtonTapped) } label: {
                        Image(systemName: "xmark").frame(width: 40, height: 40)
                    }.accessibilityLabel("학습 통계 닫기")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { store.send(.statsButtonTapped) } label: {
                        HStack(spacing: 2) {
                            Text("학습 통계")
                            Image(systemName: "chevron.right")
                        }
                    }.accessibilityLabel("학습 통계")
                }
            }
    }
}

#Preview {
    NavigationStack {   // 툴바를 보려면 필요
        CalendarView(store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature(onClose: {}, onNavigate: { _ in })
        })
    }
}
