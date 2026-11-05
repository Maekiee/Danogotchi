import SwiftUI

struct StudyStatsWordListView: View {
    let list: StudyStatsWordList
    let onSelect: (StudyStats.Word) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                StudyStatsHeading(
                    title: String(localized: "\(list.period.title) 학습 단어"),
                    subtitle: String(
                        localized: "\(StudyStatsStyle.range(list.start, list.end, calendar: list.calendar)) · 중복 제외 \(list.words.count)개"
                    )
                )
                Text("정답 횟수순 · 단어를 누르면 상세 내용을 볼 수 있어요.")
                    .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
                if list.words.isEmpty { StudyStatsSelection(text: String(localized: "아직 학습한 단어가 없어요.")) }
                ForEach(list.words) { word in
                    Button { onSelect(word) } label: {
                        StudyStatsWordCard(word: word)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }.padding(AppSpacing.space20)
        }
        .font(StudyStatsStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
        .navigationTitle("학습한 단어")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onClose) { Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44) }
                    .accessibilityLabel("학습 통계 닫기")
            }
        }
    }
}
