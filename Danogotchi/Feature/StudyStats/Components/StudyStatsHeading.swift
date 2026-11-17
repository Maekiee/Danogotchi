import SwiftUI

// 카드 제목·부제 UI
struct StudyStatsHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space4) {
            Text(title).font(StudyStatsStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            Text(subtitle).font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                .foregroundStyle(Color(AppColor.textSecondary))
        }
    }
}
