import SwiftUI

// 제목·부제 UI
struct CalendarHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space4) {
            Text(title).font(CalendarStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .foregroundStyle(Color(AppColor.textSecondary))
            }
        }
    }
}
