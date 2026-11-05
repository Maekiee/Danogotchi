import SwiftUI

// 캘린더 단어 카드에서 여는 상세 시트, 그날 풀이만
struct CalendarWordDetailView: View {
    let word: VocabStats

    var body: some View {
        ScrollView {
            CalendarWordDetailCard(word: word)
                .accessibilityIdentifier("calendar.detailCard")
                .padding(AppSpacing.space20)
        }
        .font(CalendarStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
    }
}
