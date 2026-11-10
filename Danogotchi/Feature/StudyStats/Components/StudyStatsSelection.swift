import SwiftUI

// 선택 항목 안내 박스 UI
struct StudyStatsSelection: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space12)
            .background(Color(AppColor.gray45).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.radius8))
    }
}
