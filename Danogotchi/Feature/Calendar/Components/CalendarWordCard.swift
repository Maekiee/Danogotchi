import SwiftUI

// 날짜별 단어 카드 UI (단어장 상세 카드 모양, 북마크 없음)
struct CalendarWordCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CalendarStyle.partTitle(word.snapshot.partOfSpeechSnapshot))
                .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                .padding(.horizontal, AppSpacing.space12)
                .frame(minHeight: 24)
                .overlay(Capsule().strokeBorder(Color(AppColor.black), lineWidth: AppBorder.regular))
            Spacer(minLength: AppSpacing.space8)
            HStack(alignment: .bottom, spacing: AppSpacing.space8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.snapshot.wordSnapshot)
                        .font(CalendarStyle.font(AppFont.title1, relativeTo: .title))
                        .lineLimit(2)
                    Text("\(word.snapshot.meaningSnapshot) · \(word.total)번 학습")
                        .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                }
                Spacer(minLength: 0)
                (Text("\(CalendarStyle.percentValue(word.correct, word.total))")
                    .font(CalendarStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
                 + Text(verbatim: "%").font(CalendarStyle.font(AppFont.font(.bold, size: 14), relativeTo: .footnote)))
                    .monospacedDigit()
                    .fixedSize()
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .padding(.bottom, AppSpacing.space20)
        // 접근성 글자 크기에서 글자가 잘리지 않도록 최소 높이로 둔다
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .foregroundStyle(Color(AppColor.black))
        .background(Color(AppColor.pastel(for: word.snapshot.wordSnapshot)))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
    }
}
