import SwiftUI

// 단어 상세 시트 카드 UI, 그날 풀이라 "이날" 접두어
struct CalendarWordDetailCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.space8) {
                Text(CalendarStyle.partTitle(word.snapshot.partOfSpeechSnapshot))
                    .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                    .padding(.horizontal, AppSpacing.space12)
                    .frame(minHeight: 24)
                    .overlay(Capsule().strokeBorder(.black, lineWidth: AppBorder.regular))
                Spacer(minLength: AppSpacing.space8)
                Text("이날 정답 \(word.correct) / \(word.total)회")
                    .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .multilineTextAlignment(.trailing)
            }
            Spacer(minLength: AppSpacing.space24)
            HStack(alignment: .bottom, spacing: AppSpacing.space12) {
                VStack(alignment: .leading, spacing: AppSpacing.space4) {
                    Text(word.snapshot.wordSnapshot)
                        .font(CalendarStyle.font(AppFont.title1, relativeTo: .title))
                    Text(word.snapshot.meaningSnapshot)
                        .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                }
                Spacer(minLength: AppSpacing.space8)
                Text("\(CalendarStyle.percentValue(word.correct, word.total))%")
                    .font(CalendarStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
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
