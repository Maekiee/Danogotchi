import ComposableArchitecture
import SwiftUI

struct StudyReportView: View {
    let store: StoreOf<StudyReportFeature>

    var body: some View {
        ZStack {
            Color(AppColor.background).ignoresSafeArea()

            Text("학습 리포트 화면 입니다.")
                .font(Font(AppFont.title2))
                .foregroundColor(Color(AppColor.textPrimary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.space20)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.closeButtonTapped)
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview("StudyReportView") {
    StudyReportView(
        store: Store(initialState: StudyReportFeature.State()) {
            StudyReportFeature(onClose: {})
        }
    )
}
#endif
