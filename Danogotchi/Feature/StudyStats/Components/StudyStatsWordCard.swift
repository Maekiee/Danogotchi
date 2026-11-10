import SwiftUI

// 단어 학습 카드 UI
struct StudyStatsWordCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.space8) {
                Text(StudyStatsStyle.partTitle(word.snapshot.partOfSpeechSnapshot))
                    .font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                    .padding(.horizontal, AppSpacing.space12)
                    .frame(minHeight: 24)
                    .overlay(Capsule().stroke(.black, lineWidth: AppBorder.regular))
                Spacer(minLength: AppSpacing.space8)
                Text("정답 \(word.correct) / \(word.total)회")
                    .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .multilineTextAlignment(.trailing)
            }
            Spacer(minLength: AppSpacing.space24)
            HStack(alignment: .bottom, spacing: AppSpacing.space12) {
                VStack(alignment: .leading, spacing: AppSpacing.space4) {
                    Text(word.snapshot.wordSnapshot)
                        .font(StudyStatsStyle.font(AppFont.title1, relativeTo: .title))
                    Text(word.snapshot.meaningSnapshot)
                        .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                }
                Spacer(minLength: AppSpacing.space8)
                Text(StudyStatsStyle.percent(word.correct, word.total))
                    .font(StudyStatsStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(18)
        .foregroundStyle(.black)
        .background(Color(AppColor.pastel(for: word.snapshot.wordSnapshot)))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
        .accessibilityElement(children: .combine)
    }
}
