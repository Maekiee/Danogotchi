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
                        StudyReportCard {
                            VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(word.snapshot.wordSnapshot).font(StudyReportStyle.font(AppFont.headline, relativeTo: .headline))
                                    Spacer()
                                    Text(StudyReportStyle.percent(word.correct, word.total)).monospacedDigit()
                                }
                                Text(word.snapshot.meaningSnapshot)
                                Text("정답 \(word.correct) / \(word.total)회")
                                    .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
                            }
                        }
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

struct StudyReportWordDetailView: View {
    let word: StudyReport.Word
    let list: StudyReportWordList
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.space24) {
                HStack(alignment: .top) {
                    StudyReportHeading(title: word.snapshot.wordSnapshot, subtitle: word.snapshot.meaningSnapshot)
                    Spacer()
                    Text(StudyReportCategoryKind.partOfSpeech.title(for: word.snapshot.partOfSpeechSnapshot))
                        .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                }
                Text("\(list.period.title) · \(StudyReportStyle.range(list.start, list.end, calendar: list.calendar))")
                Text("\(StudyReportCategoryKind.topic.title(for: word.snapshot.topicSnapshot)) · 최근 학습 \(StudyReportStyle.date(word.snapshot.createAt, calendar: list.calendar, format: "yyyy.M.d HH:mm"))")
                    .foregroundStyle(.secondary)
                StudyReportCard {
                    StudyReportHeading(title: StudyReportStyle.percent(word.correct, word.total), subtitle: "정답률")
                    StudyReportHeading(title: "\(word.correct) / \(word.total)회", subtitle: "정답 / 풀이")
                }
                Button("닫기", action: onClose)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(AppColor.primary))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }.padding(AppSpacing.space24)
        }
        .font(StudyReportStyle.font(AppFont.body))
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
    }
}
