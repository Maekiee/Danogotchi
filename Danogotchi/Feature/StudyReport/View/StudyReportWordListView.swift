import SwiftUI

struct StudyReportWordListView: View {
    let list: StudyReportWordList
    let onSelect: (StudyReport.Word) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                StudyReportHeading(
                    title: "\(list.period.title) 학습 단어",
                    subtitle: "\(StudyReportStyle.range(list.start, list.end, calendar: list.calendar)) · 중복 제외 \(list.words.count)개"
                )
                Text("정답 횟수순 · 단어를 누르면 상세 내용을 볼 수 있어요.")
                    .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
                if list.words.isEmpty { StudyReportSelection(text: "아직 학습한 단어가 없어요.") }
                ForEach(list.words) { word in
                    Button { onSelect(word) } label: {
                        StudyReportWordCard(word: word)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }.padding(AppSpacing.space20)
        }
        .font(StudyReportStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
        .navigationTitle("학습한 단어")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onClose) { Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44) }
                    .accessibilityLabel("학습 리포트 닫기")
            }
        }
    }
}
