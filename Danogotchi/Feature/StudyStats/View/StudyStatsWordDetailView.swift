import SwiftUI

struct StudyStatsWordDetailView: View {
    let word: StudyStats.Word

    var body: some View {
        ScrollView {
            StudyStatsWordCard(word: word)
                .accessibilityIdentifier("studyStats.detailCard")
                .padding(AppSpacing.space20)
        }
        .font(StudyStatsStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
        .accessibilityIdentifier("studyStats.wordDetail")
    }
}
