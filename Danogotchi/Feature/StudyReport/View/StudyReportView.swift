import ComposableArchitecture
import SwiftUI

struct StudyReportView: View {
    let store: StoreOf<StudyReportFeature>
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                if let report = store.report { summary(report) }
                periodPicker
                if store.isLoading {
                    loading
                } else if store.hasError {
                    errorState
                } else if let report = store.report {
                    if report.totalAnswers == 0 {
                        emptyState
                    } else {
                        analysis(report)
                    }
                    Text("단어·단어장을 삭제해도 학습 기록은 남아요.")
                        .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, AppSpacing.space12)
                }
            }
            .padding(AppSpacing.space20)
        }
        .background(Color(AppColor.background).ignoresSafeArea())
        .foregroundStyle(Color(AppColor.textPrimary))
        .font(StudyReportStyle.font(AppFont.body))
        .navigationTitle("학습 리포트")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.closeButtonTapped) } label: {
                    Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("학습 리포트 닫기")
            }
        }
        .task { store.send(.appeared) }
        .onDisappear { store.send(.disappeared) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.refresh) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in store.send(.refresh) }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in store.send(.refresh) }
    }

    private var periodPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space8) {
            Picker("분석 기간", selection: Binding(get: { store.period }, set: { store.send(.periodChanged($0)) })) {
                ForEach(StudyReportPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("studyReport.period")
            if let report = store.report, report.period == store.period {
                HStack {
                    Text(StudyReportStyle.range(report.periodStart, report.now, calendar: report.calendar))
                    Spacer()
                    Text("아래 차트에 적용")
                }
                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                .foregroundStyle(.secondary)
            }
        }
    }

    private func summary(_ report: StudyReport) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.space16) {
            Text("\(StudyReportStyle.date(report.now, calendar: report.calendar, format: "yyyy년 M월 d일")) 기준")
                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                .foregroundStyle(.secondary)
            StudyReportCard {
                let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                layout {
                    Button { store.send(.wordsTapped(.all)) } label: {
                        metric("누적 학습 단어 ›", value: "\(report.allWords.count)개", note: "중복 제외 · 전체 기간")
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isLoading || store.hasError)
                    metric("총 정답률", value: StudyReportStyle.percent(report.totalCorrect, report.totalAnswers),
                           note: "정답 \(report.totalCorrect) / 풀이 \(report.totalAnswers)회")
                }
                Divider()
                VStack(alignment: .leading, spacing: AppSpacing.space12) {
                    Text("\(report.streak)일 연속 학습")
                        .font(StudyReportStyle.font(AppFont.headline, relativeTo: .headline))
                    Text("최근 7일 학습 여부")
                        .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 4 : 7)) {
                        ForEach(report.recentDays) { day in
                            VStack(spacing: AppSpacing.space8) {
                                Text(StudyReportStyle.date(day.date, calendar: report.calendar, format: "E"))
                                Image(systemName: day.count > 0 ? "checkmark.circle.fill" : "minus.circle")
                                    .foregroundStyle(day.count > 0 ? Color(AppColor.primary) : Color(AppColor.gray45))
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(StudyReportStyle.date(day.date, calendar: report.calendar, format: "M월 d일")), \(day.count > 0 ? "학습함" : "학습 안 함")")
                        }
                    }
                    .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                }
            }
            let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
            layout {
                periodMetric("최근 7일 학습 단어", count: report.weekWordCount,
                             start: StudyReportPeriod.week.start(now: report.now, calendar: report.calendar)!, report: report)
                periodMetric("이번 달 학습 단어", count: report.monthWordCount,
                             start: StudyReportPeriod.month.start(now: report.now, calendar: report.calendar)!, report: report)
            }
        }
    }

    private func metric(_ title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.space8) {
            Text(title).font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
            Text(value).font(StudyReportStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
            Text(note).font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func periodMetric(_ title: String, count: Int, start: Date, report: StudyReport) -> some View {
        StudyReportCard {
            metric(title, value: "\(count)개", note: "\(StudyReportStyle.date(start, calendar: report.calendar)) – \(StudyReportStyle.date(report.now, calendar: report.calendar)) · 중복 제외")
        }
    }

    @ViewBuilder
    private func analysis(_ report: StudyReport) -> some View {
        if report.periodAnswerCount == 0 {
            StudyReportSelection(text: "선택한 기간에 학습 기록이 없어요. 다른 기간을 선택해 보세요.")
        }
        StudyReportCard {
            StudyReportHeading(title: "학습한 단어 수", subtitle: report.period == .all ? "월별 고유 단어 수" : "일별 고유 단어 수")
            Text("\(report.words.count)개 · \(report.period.title) 중복 제외")
                .font(StudyReportStyle.font(AppFont.title2, relativeTo: .title2))
            StudyReportActivityChart(report: report, selected: Binding(
                get: { store.selectedActivity }, set: { store.send(.activitySelected($0)) }
            ))
        }
        StudyReportCard {
            StudyReportHeading(title: "회차별 정답률", subtitle: "완료한 회차 · 최근 최대 10개 · \(report.sessions.count)회차")
            StudyReportSessionChart(report: report, selected: Binding(
                get: { store.selectedSession }, set: { store.send(.sessionSelected($0)) }
            ))
            Text("답변을 모두 저장한 회차만 표시해요. 중단한 회차의 답변도 누적 통계에는 포함돼요.")
                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
        }
        StudyReportCard {
            StudyReportHeading(title: "주제별 학습 비중", subtitle: "반복 풀이 포함 · 총 \(report.periodAnswerCount)회")
            StudyReportCategoryBars(categories: report.topics, kind: .topic, selected: store.selectedTopic) {
                store.send(.topicSelected($0))
            }
        }
        StudyReportCard {
            StudyReportHeading(title: "학습 단어의 품사", subtitle: "기간 내 고유 단어 · 마지막 학습 시점 기준")
            StudyReportPartsChart(report: report, selected: store.selectedPart) { store.send(.partSelected($0)) }
                .id(report.period)
            Text("미분류를 포함한 \(report.words.count)개 단어가 기준이에요.")
                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
        }
        StudyReportCard {
            StudyReportHeading(title: "많이 틀린 종류", subtitle: "오답 횟수 기준")
            Picker("오답 분류", selection: Binding(get: { store.mistakeKind }, set: { store.send(.mistakeKindChanged($0)) })) {
                ForEach(StudyReportCategoryKind.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            StudyReportCategoryBars(
                categories: store.mistakeKind == .topic ? report.topics : report.mistakesByPart,
                kind: store.mistakeKind, showsMistakes: true, selected: store.selectedMistake
            ) { store.send(.mistakeSelected($0)) }
            Text("오답 횟수와 함께 전체 풀이 수·오답률을 비교해 보세요.")
                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
        }
        StudyReportCard {
            HStack(alignment: .top) {
                StudyReportHeading(title: "많이 맞힌 단어", subtitle: "정답 횟수 TOP 5")
                Spacer()
                Button("전체 보기") { store.send(.wordsTapped(store.period)) }
                    .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                    .frame(minHeight: 44)
            }
            if report.words.isEmpty {
                StudyReportSelection(text: "선택한 기간에 학습한 단어가 없어요.")
            }
            ForEach(Array(report.words.prefix(5).enumerated()), id: \.element.id) { index, word in
                Button { store.send(.wordTapped(word.id)) } label: {
                    HStack(alignment: .top, spacing: AppSpacing.space12) {
                        Text(String(format: "%02d", index + 1)).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: AppSpacing.space8) {
                            HStack { Text(word.snapshot.wordSnapshot).bold(); Spacer(); Text("\(word.correct)회") }
                            Text(word.snapshot.meaningSnapshot).foregroundStyle(.secondary)
                            StudyReportHorizontalBar(value: word.correct, maximum: report.words.first?.correct ?? 1)
                            Text("정답률 \(StudyReportStyle.percent(word.correct, word.total)) · 전체 \(word.total)회 풀이")
                                .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote)).foregroundStyle(.secondary)
                        }
                    }.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var loading: some View {
        VStack(spacing: AppSpacing.space16) {
            ProgressView("학습 기록을 불러오고 있어요.").padding()
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: AppRadius.radius16)
                    .fill(Color(AppColor.gray45).opacity(0.12)).frame(height: 150)
                    .accessibilityHidden(true)
            }
        }.frame(maxWidth: .infinity)
    }

    private var errorState: some View {
        StudyReportCard {
            Image(systemName: "exclamationmark.circle").font(.largeTitle)
            StudyReportHeading(title: "기록을 불러오지 못했어요", subtitle: "잠시 후 다시 시도해 주세요. 저장된 학습 기록은 그대로 남아 있어요.")
            Button("다시 시도") { store.send(.refresh) }
                .buttonStyle(.borderedProminent).tint(Color(AppColor.primary))
                .frame(minHeight: 44)
        }
    }

    private var emptyState: some View {
        StudyReportCard {
            Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Color(AppColor.primary))
            StudyReportHeading(title: "첫 학습을 기다리고 있어요", subtitle: "퀴즈에서 답변을 저장하면 학습량과 정답률을 확인할 수 있어요.")
        }
    }
}
