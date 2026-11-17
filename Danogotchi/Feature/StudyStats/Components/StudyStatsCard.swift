import SwiftUI

// 통계 카드 컨테이너 UI
struct StudyStatsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space20)
            .background(Color(AppColor.card))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius16))
    }
}
