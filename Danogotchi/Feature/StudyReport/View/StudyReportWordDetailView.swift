import SwiftUI

struct StudyReportWordDetailView: View {
    let word: StudyReport.Word

    var body: some View {
        ScrollView {
            StudyReportWordCard(word: word)
                .accessibilityIdentifier("studyReport.detailCard")
                .padding(AppSpacing.space20)
        }
        .font(StudyReportStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
        .accessibilityIdentifier("studyReport.wordDetail")
    }
}
